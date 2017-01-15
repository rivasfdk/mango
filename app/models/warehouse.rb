class Warehouse < ActiveRecord::Base
  attr_protected :id

  belongs_to :ingredient
  belongs_to :product
  belongs_to :warehouse_types

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :code, :name, length: {within: 3..40}
  validates :stock, numericality: {greater_than_or_equal_to: 0}

  validate :ingredient_id_xor_product_id


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

  
  def to_collection_select
    "#{self.warehouse_types.name} - #{self.code} - #{self.name}"
  end


  def is_a_number?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
  end

  private 

    def ingredient_id_xor_product_id
      unless ingredient_id.blank? ^ product_id.blank?
        errors.add(:base, "Debe especificar una materia prima o un producto (no ambos)")
      end
    end
end