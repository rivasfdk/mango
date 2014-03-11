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
  validates :prog_batches, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :real_batches, numericality: {allow_nil: true}
  validates :real_production, numericality: {allow_nil: true}
  validate :product_lot_factory

  before_save :create_code, if: :new_record?

  def product_lot_factory
    if self.client and self.product_lot
      if self.client.factory and not self.product_lot.client_id == self.client_id
        errors.add(:product_lot, "no pertenece a la fabrica")
      end
    end
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
    order_number = OrderNumber.first
    self.code = order_number.code.succ
    order_number.code = self.code
    order_number.save
  end

  def repair(user_id, n_batch)  
    hopper_ingredients = HopperLot.joins(:lot)
                                  .where(active: true)
                                  .pluck_all("hoppers_lots.id", "lots.ingredient_id")
                                  .inject({}) do |hash, hl|
      hash[hl["ingredient_id"]] = hl["id"]
      hash
    end

    recipe_ingredients = IngredientRecipe.where(recipe_id: self.recipe_id)
                                         .pluck_all(:ingredient_id, :amount)
                                         .inject({}) do |hash, ir|
      hash[ir["ingredient_id"]] = ir["amount"]
      hash
    end

    unless self.medicament_recipe.nil?
      recipe_ingredients = IngredientMedicamentRecipe.where(recipe_id: self.medicament_recipe_id)
                                                     .pluck_all(:ingredient_id, :amount)
                                                     .inject(recipe_ingredients) do |hash, ir|
        hash[ir["ingredient_id"]] = ir["amount"] unless hash.has_key? ir["ingredient_id"]
        hash
      end                                                         
    end

    return false unless (recipe_ingredients.keys - hopper_ingredients.keys).empty?

    transaction do
      BatchHopperLot.skip_callback(:create, :after, :update_batch_end_date)
      now = Time.now
      real_batch = self.batch.count
      if real_batch < n_batch
        schedule_id = Schedule.get_current_schedule_id(now)
        (n_batch - real_batch).times do |n|
          batch = self.batch.new user_id: user_id,
                                 number: real_batch + n + 1,
                                 schedule_id: schedule_id,
                                 start_date: now,
                                 end_date: now
          batch.save(validate: false)
          recipe_ingredients.each do |key, value|
            batch.batch_hopper_lot.new(hopper_lot_id: hopper_ingredients[key],
                                       standard_amount: value,
                                       amount: value)
                                  .save(validate: false)
          end
        end
      end

      # Bro do you even ruby?
      batches_ingredients = self.batch
                                .joins(batch_hopper_lot: {hopper_lot: {lot: {}}})
                                .pluck_all("batches.id", "lots.ingredient_id")
                                .inject(Hash.new {|hash, key| hash[key] = []}) do |hash, bi|
        hash[bi["id"]] << bi["ingredient_id"]
        hash
      end

      batches_ingredients.each do |batch_id, ingredients_ids|
        missing_ingredients = recipe_ingredients.keys - ingredients_ids
        missing_ingredients.each do |ingredient_id|
          BatchHopperLot.new(batch_id: batch_id,
                             hopper_lot_id: hopper_ingredients[ingredient_id],
                             standard_amount: recipe_ingredients[ingredient_id],
                             amount: recipe_ingredients[ingredient_id])
                        .save(validate: false)
        end
      end
      BatchHopperLot.set_callback(:create, :after, :update_batch_end_date)

      extra_batches_ids = self.batch.where(['number > ?', n_batch]).pluck(:id)
      unless extra_batches_ids.empty?
        BatchHopperLot.where(batch_id: extra_batches_ids).delete_all
        Batch.where(id: extra_batches_ids).delete_all
      end

      Order.where(id: self.id)
           .update_all({prog_batches: n_batch,
                        real_batches: n_batch,
                        completed: true,
                        repaired: true,
                        updated_at: now})
    end
    self.generate_transactions(user_id) if is_mango_feature_available("transactions")
  end

  def self.generate_consumption(params, user_id)
    errors = []
    # Add some shitty error handling
    if errors.empty?
      now = Time.now
      order = Order.find_by_code params[:order_code]
      batch = order.batch
                   .find_or_create_by_number number: params[:batch_number],
                                             schedule_id: Schedule.get_current_schedule_id(now),
                                             user_id: user_id,
                                             start_date: now,
                                             end_date: now
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
          hopper_lot.save(validate: false)
        end
      end

      batch_hopper_lot = batch.batch_hopper_lot.new
      batch_hopper_lot.hopper_lot_id = hopper_lot.id
      batch_hopper_lot.amount = params[:amount]
      batch_hopper_lot.standard_amount = order.get_standard_amount(hopper_lot.lot.ingredient_id)

      if batch_hopper_lot.save
        mango_features = get_mango_features()
        batch_hopper_lot.generate_transaction(user_id) if mango_features.include? "transactions"
        if mango_features.include? "hoppers_transactions"
          batch_hopper_lot.hopper_lot = original_hopper_lot
          batch_hopper_lot.generate_hopper_transaction(user_id)
        end
      end
    end
    errors
  end

  def self.generate_not_weighed_consumptions(params, user_id)
    errors = []
    now = Time.now
    order = Order.find_by_code(params[:order_code])

    amounts = IngredientRecipe.where(recipe_id: order.recipe_id)
                              .pluck_all(:ingredient_id, :amount)
                              .inject({}) do |hash, item|
      hash[item["ingredient_id"]] = item["amount"]
      hash
    end

    hopper_amounts = HopperLot.joins({hopper: {scale: {}},
                                      lot: {ingredient: {}}})
                              .where({active: true,
                                      hoppers: {main: true},
                                      scales: {not_weighed: true},
                                      ingredients: {id: amounts.keys}})
                              .pluck_all("hoppers_lots.id",
                                         "ingredient_id")
                              .inject({}) do |hash, item|
      hash[item["id"]] = amounts[item["ingredient_id"]]
      hash
    end

    batch = order.batch
                 .find_or_create_by_number(number: params[:batch_number],
                                           schedule_id: Schedule.get_current_schedule_id(now),
                                           user_id: user_id,
                                           start_date: now,
                                           end_date: now)
    transaction do
      hopper_amounts.each do |hopper_lot_id, amount|
         bhl = batch.batch_hopper_lot
                    .create(hopper_lot_id: hopper_lot_id,
                            amount: amount,
                            standard_amount: amount)
        if is_mango_feature_available("transactions")
          bhl.generate_transaction(user_id)
        end
      end
    end
    errors
  end

  def self.consumption_exists(params)
    BatchHopperLot.includes({batch: {order: {}},
                             hopper_lot: {hopper: {}}})
                  .where({orders: {code: params[:order_code]},
                          batches: {number: params[:batch_number]},
                          hoppers: {scale_id: params[:scale_id],
                                    number: params[:hopper_number]}})
                  .any?
  end

  def close(user_id)
    self.generate_transactions(user_id) if is_mango_feature_available("transactions")
    self.update_column(:completed, true)
  end

  def self.create_order_stat(params)
    order_stat_type_id = params[:order_stat_type_id].to_i
    order_id = OrderArea.joins(area: {orders_stats_types: {}})
                        .where(active: true,
                               orders_stats_types: {id: order_stat_type_id})
                        .pluck(:order_id)
                        .first
    OrderStat.create(order_id: order_id,
                     order_stat_type_id: order_stat_type_id,
                     value: params[:value])
             .errors
             .messages
  end

  def self.update_order_area(params)
    errors = {}
    order_id = Order.where(code: params[:order_code]).pluck(:id).first
    area_id = Area.where(id: params[:area_id]).pluck(:id).first
    errors[:order_code] = "no existe" if order_id.nil?
    errors[:area_id] = "no existe" if area_id.nil?
    OrderArea.new(order_id: order_id, area_id: area_id)
             .save(validate: false) if errors.empty?
    errors
  end

  def get_standard_amount(ingredient_id)
    if self.medicament_recipe_id.nil?
      IngredientRecipe.where({recipe_id: self.recipe_id,
                              ingredient_id: ingredient_id})
                      .pluck(:amount)
                      .first ||
      0
    else
      IngredientRecipe.where({recipe_id: self.recipe_id,
                              ingredient_id: ingredient_id})
                      .pluck(:amount)
                      .first ||
      IngredientMedicamentRecipe.where({medicament_recipe_id: self.medicament_recipe_id,
                                        ingredient_id: ingredient_id})
                                .pluck(:amount)
                                .first ||
      0
    end
  end

  def generate_transactions(user_id)
    consumptions = {}
    order_transactions = self.transactions
    batches = Batch.includes({batch_hopper_lot: {hopper_lot: {}}})
                   .where(order_id: self.id)
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
      previous_amount = order_transactions.inject(0) do |sum, t|
        (t.content_type == 1 and t.content_id == key) ? sum + t.amount : sum
      end
      amount = amount - previous_amount unless previous_amount == 0
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

    previous_amount = order_transactions.inject(0) do |sum, t|
      (t.content_type == 2) ? sum + t.amount : sum
    end
    production = production - previous_amount unless previous_amount == 0
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
    orders = Order.includes(:recipe, :client, product_lot: {product: {}})
    orders = orders.where(code: params[:code]) if params[:code].present?
    orders = orders.where(recipes: {code: params[:recipe_code]}) if params[:recipe_code].present?
    orders = orders.where(client_id: params[:client_id]) if params[:client_id].present?
    orders = orders.where('orders.created_at >= ?', Date.parse(params[:start_date])) if params[:start_date].present?
    orders = orders.where('orders.created_at <= ?', Date.parse(params[:end_date]) + 1.day) if params[:end_date].present?
    orders = orders.order('orders.created_at DESC')
    orders.paginate page: params[:page], per_page: params[:per_page]
  end
end
