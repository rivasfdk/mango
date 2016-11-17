class Warehouse < ActiveRecord::Base
  attr_protected :id

  belongs_to :ingredient
  belongs_to :product
  belongs_to :warehouse_types

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :code, :name, length: {within: 3..40}
  validates :stock, numericality: {greater_than_or_equal_to: 0}


  def adjust(amount)
      diff = self.stock - amount
      if amount < 0
        logger.debug("stock can't be negative")
        false
      elsif amount > self.size
        logger.debug("stock exceeds capacity")
        false
      else 
        self.stock = diff.abs
      end
  end

  def change(params, user_id)
    if is_a_number? params[:stock]
      stock = params[:stock].to_f
      new_ingredient_id = params[:ingredient_id].to_i
      if @warehouse.ingredient.id == new_ingredient_id
        logger.debug("ingredient can't be the same")
        false
      elsif stock < 0
        logger.debug("stock can't be less than or equal to 0")
        false
      elsif stock > @warehouse.size
        logger.debug("stock exceeds capacity")
        false
      else
        @warehouse.save
      end
    else
      false
    end
  end


  def eliminate
    begin
      b = Warehouse.includes(:warehouse_ingredient).where({warehouses_ingredients: {warehouse_id: self.id}})
      if b.any?
        errors.add(:foreign_key, 'no se puede eliminar porque tiene registros asociados')
        return
      end

      self.hopper_lot.each do |i|
        i.destroy
      end
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
end


  