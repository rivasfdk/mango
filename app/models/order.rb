class Order < ActiveRecord::Base
  belongs_to :recipe
  belongs_to :medicament_recipe
  belongs_to :client
  belongs_to :user
  belongs_to :product_lot
  has_many :batch
  has_many :alarms

  validates_presence_of :recipe_id, :user_id, :product_lot_id, :client_id
  validates_numericality_of :prog_batches, :real_batches, :only_integer => 0, :greater_than_or_equal_to => 0
  validates_associated :recipe, :client, :user

  before_validation :validates_real_batchs
  before_save :create_code

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
    last_batch = Batch.find(:first, :conditions => ["number = ? and order_id = ?", self.get_real_batches, self.id])
    if last_batch.nil?
      return "??/??/???? ??:??:??"
    end
    end_date = BatchHopperLot.where(:batch_id=>last_batch.id).maximum('created_at')
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
    real_batches = 0
    Batch.where(:order_id => self.id).each do |batch|
      real_batches += 1 unless BatchHopperLot.where(:batch_id => batch.id).empty?
    end
    return real_batches
  end

  def create_code
    unless self.id
      order = OrderNumber.first
      self.code = order.code.succ
      order.code = self.code
      order.save
    end
  end

  def repair(user, n_batch)    
    if self.batch.count == 0
      self.prog_batches.times do |n|
        batch = self.batch.new
        batch.user = user
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
    self.save

    self.generate_transactions(user)
  end

  def generate_transactions(user)
    order = Order.find self.id
    consumptions = {}
    order.batch.each do |b|
      b.batch_hopper_lot.each do |bhl|
        key = bhl.hopper_lot.lot.id
        if consumptions.has_key? key
          consumptions[key] += bhl.amount
        else
          consumptions[key] = bhl.amount
        end
      end
    end
    production = 0
    consumptions.each do |key, value|
      production += value
      warehouse = Warehouse.find :first, :conditions => ['warehouse_type_id = 1 and content_id = ?', key]
      if warehouse.nil?
        return false
      end
      t = Transaction.new
      t.transaction_type_id = 1
      t.processed_in_stock = 1
      t.amount = value
      t.user = user
      t.warehouse = warehouse
      t.save
    end
    warehouse = Warehouse.find :first, :conditions => ['warehouse_type_id = 2 and content_id = ?', self.product_lot_id]
    if warehouse.nil?
      return false
    end
    t = Transaction.new
    t.transaction_type_id = 6
    t.processed_in_stock = 1
    t.amount = production
    t.user = user
    t.warehouse = warehouse
    t.save
  end
  
  def self.search(search, page, per_page)
    if search and search != ""
      paginate :all, :page => page,
               :per_page => per_page,
               :order => 'created_at DESC',
               :conditions => ['code = ?', search]
    else
      paginate :all, :page => page, :per_page => per_page
    end
  end
end
