include MangoModule

class Order < ActiveRecord::Base
  belongs_to :recipe
  belongs_to :medicament_recipe
  belongs_to :parameter_list
  belongs_to :client
  belongs_to :user
  belongs_to :product_lot
  has_many :batch
  has_many :alarms
  has_many :transactions
  has_many :order_stats
  has_many :areas

  validates :recipe, :user, :product_lot, :client, presence: true
  validates :prog_batches, :real_batches, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :real_production, numericality: {allow_nil: true}
  validate :product_lot_factory

  before_validation :validates_real_batchs
  before_save :create_code

  def product_lot_factory
    if self.client and self.product_lot
      if self.client.factory and not self.product_lot.client_id == self.client_id
        errors.add(:product_lot, "no pertenece a la fabrica")
      end
    end
  end

  def validates_real_batchs
    self.real_batches = 0 if self.real_batches.nil?
    true
  end

  def calculate_short_start_date
    self.batch.first.nil? ? "??/??/???? ??:??:??" : self.batch.first.start_date.strftime("%d/%m/%Y")
  end

  def calculate_start_date
    self.batch.first.nil? ? "??/??/???? ??:??:??" : self.batch.first.start_date.strftime("%d/%m/%Y %H:%M:%S")
  end

  def calculate_end_date
    self.batch.last.nil? ? "??/??/???? ??:??:??" : self.batch.last.end_date.strftime("%d/%m/%Y %H:%M:%S")
  end

  def calculate_duration
    start_date = self.batch.first.nil? ? nil : self.batch.first.start_date
    end_date = self.batch.last.nil? ? nil : self.batch.last.end_date

    start_date_string = start_date.nil? ? "??:??:??" : start_date.strftime("%H:%M:%S") 
    end_date_string = end_date.nil? ? "??:??:??" : end_date.strftime("%H:%M:%S")

    duration_value = (start_date.nil? or end_date.nil?) ? 0 : (end_date - start_date) / 60.0

    {start_date: start_date_string, end_date: end_date_string, duration: duration_value}
  end

  def get_real_batches
    self.batch.count
  end

  def create_code
    if self.new_record?
      order = OrderNumber.first
      self.code = order.code.succ
      order.code = self.code
      order.save
    end
  end

  def repair(user_id, n_batch)    
    if self.batch.count == 0
      self.prog_batches.times do |n|
        batch = self.batch.new
        batch.user_id = user_id
        batch.number = n + 1
        batch.schedule = Schedule.first
        batch.start_date = Date.today
        batch.end_date = Date.today
        batch.save
      end
    end

    hopper_ingredients = {}
    hopper_lots = HopperLot.where :active => true
    hopper_lots.each do |hl|
      hopper_ingredients[hl.lot.ingredient.id] = hl.id
    end

    recipe_ingredients = {}
    self.recipe.ingredient_recipe.each do |ir|
      recipe_ingredients[ir.ingredient.id] = ir.amount
    end

    self.batch.each do |batch|
      if batch.number > n_batch
        break
      end
      batch_ingredients = []
      batch.batch_hopper_lot.each do |bhl|
        batch_ingredients << bhl.hopper_lot.lot.ingredient.id
      end
      recipe_ingredients.each do |key, value|
        unless batch_ingredients.include? key
          bhl = batch.batch_hopper_lot.new
          bhl.hopper_lot_id = hopper_ingredients[key]
          bhl.amount = value
          bhl.save
        end
      end
    end

    extra_batches = Batch.find :all, :conditions => ['order_id = ? and number > ?', self.id, n_batch]
    extra_batches.each do |b|
      b.batch_hopper_lot.each do |bhl|
        bhl.delete
      end
      b.delete
    end

    self.prog_batches = n_batch
    self.real_batches = n_batch
    self.completed = true
    self.repaired = true
    self.save

    if is_mango_feature_available("transactions")
      self.generate_transactions(user_id)
    end
  end

  def self.generate_consumption(params, user_id)
    errors = []
    # Add some shitty error handling
    if errors.empty?
      order = Order.find_by_code params[:order_code], include: {client: {}, recipe: {ingredient_recipe: {}}, medicament_recipe: {ingredient_medicament_recipe: {}}}
      batch = order.batch.find_or_create_by_number params[:batch_number]
      if batch.new_record?
        now = Time.now
        batch.schedule = Schedule.get_current_schedule(now)
        batch.user_id = user_id
        batch.start_date = now
        batch.end_date = now
        batch.save
        logger.debug("Errores de batch")
        logger.debug(batch.errors.messages)
      end
      hopper = Hopper.where({scale_id: params[:scale_id], 
                             number: params[:hopper_number]}).first

      hopper_lot = hopper.current_hopper_lot
      original_hopper_lot = hopper_lot # Horrible

      if order.client.factory
        hfl = HopperFactoryLot.where(hopper_lot_id: hopper_lot.id, client_id: order.client_id).first
        if hfl.present? and hfl.lot_id.present?
          hopper_lot = hopper.hopper_lot.new
          hopper_lot.lot_id = hfl.lot_id
          hopper_lot.active = false
          hopper_lot.factory = true
          hopper_lot.save
        end
      end

      batch_hopper_lot = batch.batch_hopper_lot.new
      batch_hopper_lot.hopper_lot_id = hopper_lot.id
      batch_hopper_lot.amount = params[:amount]
      batch_hopper_lot.standard_amount = order.get_standard_amount(hopper_lot.lot.ingredient_id)
      if batch_hopper_lot.save
        if is_mango_feature_available("transactions")
          batch_hopper_lot.generate_transaction(user_id)
        end
        if is_mango_feature_available("hoppers_transactions")
          batch_hopper_lot.hopper_lot = original_hopper_lot
          batch_hopper_lot.generate_hopper_transaction(user_id)
        end
      else
        logger.debug("Errores de batch_hopper_lot")
        logger.debug(batch_hopper_lot.errors.messages)
      end
    end
    errors
  end

  def self.consumption_exists(params)
    logger.debug("revisando orden")
    conditions = ['orders.code = ? and batches.number = ? and hoppers.scale_id = ? and hoppers.number = ?',
                  params[:order_code], 
                  params[:batch_number],
                  params[:scale_id],
                  params[:hopper_number]]
    BatchHopperLot.includes({batch: {order: {}},
                             hopper_lot: {hopper: {}}}).where(conditions).any?
  end

  def close(user_id)
    if is_mango_feature_available("transactions")
      self.generate_transactions(user_id)
    end
    self.completed = true
    self.save
  end

  def self.create_order_stat(params)
    errors = []
    order_stat_type_id = params[:order_stat_type_id]
    order_id = OrderArea.joins(area: {orders_stats_types: {}})
                        .where(active: true, orders_stats_types: {id: order_stat_type_id})
                        .pluck(:order_id).first
    order_stat = OrderStat.new
    order_stat.order_id = order_id
    order_stat.order_stat_type_id = order_stat_type_id
    order_stat.value = params[:value]
    order_stat.save
    logger.debug(order_stat.errors.messages)
    errors
  end

  def get_standard_amount(ingredient_id)
    standard_amount = IngredientRecipe.where({recipe_id: self.recipe_id, ingredient_id: ingredient_id}).pluck(:amount).first
    unless standard_amount.nil?
      standard_amount
    else
      if self.medicament_recipe_id.present?
        standard_amount = IngredientMedicamentRecipe.where({medicament_recipe_id: self.medicament_recipe_id, ingredient_id: ingredient_id}).pluck(:amount).first
        standard_amount.nil? ? 0 : standard_amount
      else
        0
      end
    end
  end

  def generate_transactions(user_id)
    consumptions = {}
    order_transactions = self.transactions
    batches = Batch.includes({batch_hopper_lot: {hopper_lot: {}}}).where(order_id: self.id)
    batches.each do |b|
      b.batch_hopper_lot.each do |bhl|
        key = bhl.hopper_lot.lot_id
        if consumptions.has_key? key
          consumptions[key] += bhl.amount
        else
          consumptions[key] = bhl.amount
        end
      end
    end
    production = 0
    consumptions.each do |key, amount|
      production += amount
      previous_amount = order_transactions.inject(0) {|sum, t| (t.content_type == 1 and t.content_id == key) ? sum + t.amount : sum}
      unless previous_amount == 0
        amount = amount - previous_amount
      end
      unless amount == 0
        t = self.transactions.new
        t.amount = amount
        t.transaction_type_id = 1
        t.content_type = 1
        t.content_id = key
        t.processed_in_stock = 1
        t.user_id = user_id
        t.save
      end
    end
    unless product_lot_id.present?
      return false
    end
    previous_amount = order_transactions.inject(0) {|sum, t| (t.content_type == 2) ? sum + t.amount : sum}
    unless previous_amount == 0
      production = production - previous_amount
    end
    unless production == 0
      t = self.transactions.new
      t.amount = production
      t.transaction_type_id = 6
      t.content_type = 2
      t.content_id = self.product_lot_id
      t.processed_in_stock = 1
      t.user_id = user_id
      t.save
    end
  end

  def self.search(params)
    orders = Order.includes(:recipe)
    orders = orders.where(code: params[:code]) if params[:code].present?
    orders = orders.where(['recipes.code = ?', params[:recipe_code]]) if params[:recipe_code].present?
    orders = orders.where(client_id: params[:client_id]) if params[:client_id].present?
    orders = orders.where('orders.created_at >= ?', Date.parse(params[:start_date])) if params[:start_date].present?
    orders = orders.where('orders.created_at <= ?', Date.parse(params[:end_date]) + 1.day) if params[:end_date].present?
    orders = orders.order('orders.created_at DESC')
    orders.paginate page: params[:page], per_page: params[:per_page]
  end
end
