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

  validates_presence_of :recipe, :user, :product_lot, :client
  validates_numericality_of :prog_batches, :real_batches, :only_integer => 0, :greater_than_or_equal_to => 0
  validates_associated :recipe, :client, :user
  validates_numericality_of :real_production, :allow_nil => true
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
    return true
  end

  def calculate_short_start_date
    start_date = Batch.where(:order_id=>self.id).minimum('created_at')
    unless start_date.nil?
      return start_date.strftime("%d/%m/%Y")
    else
      return "??/??/????"
    end
  end

  def calculate_start_date
    start_date = Batch.where(:order_id=>self.id).minimum('created_at')
    unless start_date.nil?
      return start_date.strftime("%d/%m/%Y %H:%M:%S")
    else
      return "??/??/???? ??:??:??"
    end
  end

  def calculate_end_date
    last_batch = self.batch.last
    if last_batch.nil?
      return "??/??/???? ??:??:??"
    end
    end_date = last_batch.batch_hopper_lot.last.created_at # last_batch.created_at for new orders
    unless end_date.nil?
      return end_date.strftime("%d/%m/%Y %H:%M:%S")
    else
      return "??/??/???? ??:??:??"
    end
  end

  def calculate_duration
    start_date = Batch.where(:order_id=>self.id).minimum('created_at')
    last_batch = Batch.find(:first, :conditions => ["number = ? and order_id = ?", Batch.where(:order_id=>self.id).maximum('number'), self.id])
    end_date = BatchHopperLot.where(:batch_id=>last_batch.id).maximum('created_at')

    start_date_string = start_date.strftime("%H:%M:%S") rescue "??:??:??"
    end_date_string = end_date.strftime("%H:%M:%S") rescue "??:??:??"
    duration_value = 0
    if not start_date.nil? and not end_date.nil?
      duration_value = (end_date.to_i - start_date.to_i) / 60.0
    end

    return {
      'start_date' => start_date_string,
      'end_date' => end_date_string,
      'duration' => duration_value
    }
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
      order = Order.find_by_code params[:order_code]
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
      hopper_id = Hopper.where({:scale_id => params[:scale_id], 
                                :number => params[:hopper_number]}).first.id
      hopper_lot_id = HopperLot.where({:hopper_id => hopper_id,
                                       :active => true}).first.id
      batch_hopper_lot = batch.batch_hopper_lot.new
      batch_hopper_lot.hopper_lot_id = hopper_lot_id
      batch_hopper_lot.amount = params[:amount]
      if batch_hopper_lot.save
        if is_mango_feature_available("transactions")
          batch_hopper_lot.generate_transaction(user_id)
        end
        if is_mango_feature_available("hoppers_transactions")
          batch_hopper_lot.generate_hopper_transaction(user_id)
        end
      else
        logger.debug("Errores de batch_hopper_lot")
        logger.debug(batch_hopper_lot.errors.messages)
      end
    end
    return errors
  end

  def self.consumption_exists(params)
    logger.debug("revisando orden")
    conditions = ['orders.code = ? and batches.number = ? and hoppers.scale_id = ? and hoppers.number = ?',
                  params[:order_code], 
                  params[:batch_number],
                  params[:scale_id],
                  params[:hopper_number]]
    BatchHopperLot.includes({:batch => {:order => {}}, 
                             :hopper_lot => {:hopper => {}}}).where(conditions).any?
  end

  def close(user_id)
    self.generate_transactions(user_id)
    self.completed = true
    self.save
  end

  def generate_transactions(user_id)
    consumptions = {}
    order_transactions = self.transactions
    batches = Batch.includes({:batch_hopper_lot => {:hopper_lot => {}}}).where(:order_id => self.id)
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
    @orders = Order.order('created_at DESC')
    @orders = @orders.includes(:recipe, :client)
    @orders = @orders.where(:code => params[:code]) if params[:code].present?
    @orders = @orders.where(:recipe_id => params[:recipe_id]) if params[:recipe_id].present?
    @orders = @orders.where(:client_id => params[:client_id]) if params[:client_id].present?
    @orders = @orders.where('created_at >= ?', Date.parse(params[:start_date])) if params[:start_date].present?
    @orders = @orders.where('created_at <= ?', Date.parse(params[:end_date]) + 1.day) if params[:end_date].present?
    @orders.paginate :page => params[:page], :per_page => params[:per_page]
  end
end
