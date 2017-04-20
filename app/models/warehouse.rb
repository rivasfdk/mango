class Warehouse < ActiveRecord::Base
  attr_protected :id

  belongs_to :lot
  belongs_to :product_lot
  belongs_to :warehouse_types

  has_many :transactions

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :code, :name, length: {within: 3..40}
  validates :stock, numericality: {greater_than_or_equal_to: 0}


  def adjust(params)
    if is_a_number? params[:stock]
      new_stock = params[:stock].to_f
      if new_stock < 0
        logger.debug("stock can't be negative")
        false
      elsif new_stock > self.size
        logger.debug("stock exceeds capacity")
        false
      else
        true
      end
    else
      false
    end
  end


  def new_amount(amount)
    new_stock = self.stock + amount.to_f
    new_stock.to_f
  end


  def fill(params)
    if is_a_number? params[:amount]
      amount = params[:amount].to_f
      logger.debug("Stock: #{self.stock}")
      logger.debug("Capacidad: #{self.size}")
      if amount <= 0 or self.stock + amount > self.size
        return false
      end
      w = Warehouse.new
      w.stock = amount
      w.save
    else
      return false
    end
  end
  

  def change(params, user_id)
    if is_a_number? params[:ingredient_id]
      new_ingredient_id = params[:ingredient_id].to_i
      if @warehouse.ingredient_id == new_ingredient_id
        logger.debug("ingredient can't be the same")
        false
      else
        true
      end
    else
      false
    end
  end

  def eliminate
    begin
      self.destroy
    rescue ActiveRecord::StatementInvalid => ex
      puts ex.inspect
      errors.add(:foreign_key, 'no se puede eliminar porque tiene registros asociados')
    rescue Exception => ex
      errors.add(:unknown, ex.message)
    end
  end

  def set_as_main_warehouse
    if self.warehouse_types.content_type
      warehouses = Warehouse.where(lot_id: self.lot_id)
    else
      warehouses = Warehouse.where(product_lot_id: self.product_lot_id)
    end
    unless warehouses.empty?
      Warehouse.update_all('main = false', :id => warehouses.map {|wh| wh.id})
    end
    self.update_attributes(main: true)
  end

  def set_main_warehouse
    self.update_attributes(main: false)
    if self.warehouse_types.content_type
      warehouses = Warehouse.where(lot_id: self.lot_id)
    else
      warehouses = Warehouse.where(product_lot_id: self.product_lot_id)
    end
    if warehouses.length == 1
      self.update_attributes(main: true)
    end
  end
  
  def to_collection_select
    "#{self.warehouse_types.name} - #{self.code} - #{self.name} - #{self.stock} Kg"
  end


  def is_a_number?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
  end
end