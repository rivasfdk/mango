class Warehouse < ActiveRecord::Base
  attr_protected :id

  belongs_to :ingredient
  belongs_to :warehouse_types

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :code, :name, length: {within: 3..40}
  validates :stock, numericality: {greater_than_or_equal_to: 0}

  def adjust(params, user_id)
    if is_a_number? params[:new_stock]
      new_stock = params[:new_stock].to_f
      if new_stock < 0
        logger.debug("stock can't be negative")
        false
      elsif new_stock > self.size
        logger.debug("stock exceeds capacity")
        false
      end
    else
      false
    end
  end

  def change(params, user_id)
    if is_a_number? params[:amount]
      amount = params[:amount].to_f
      new_ingredient_id = params[:ingredient_id].to_i
      if current_ingredient.id == new_lot_id
        logger.debug("ingredient can't be the same")
        false
      elsif amount < 0
        logger.debug("amount can't be less than or equal to 0")
        false
      elsif amount > capacity_in_kg_by_lot(new_lot_id)
        logger.debug("amount exceeds capacity")
        false
      else
        hl = self.hopper_lot.new
        hl.lot_id = new_lot_id
        hl.save
        hlt = hl.hopper_lot_transactions.new
        hlt.hopper_lot_transaction_type_id = 1
        hlt.amount = amount
        hlt.user_id = user_id
        hlt.save
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

      #If there is no main hopper for the hopper ingredient after deleting the hopper
      #set hopper.main to true to the first hopper with the ingredient (if any)
      current_hopper_lot = HopperLot.includes(:lot).where(active: true, hopper_id: self.id).first
      hoppers = Hopper.includes({hopper_lot: :lot}).where(['hoppers.id != ? and hoppers_lots.active = true and lots.ingredient_id = ?', self.id, current_hopper_lot.lot.ingredient_id]).order('hoppers.scale_id, hoppers.number ASC')
      unless hoppers.empty?
        if hoppers.select {|hopper| hopper.main == true}.empty?
          hoppers.first.main = true
          hoppers.first.save
        end
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

  def current_ingredient
    warehouse_ingredient = Warehouse.includes(:ingredient).where(warehouse_id: self.id, active: true).first
    return warehouse_ingredient.nil? ? nil : warehouse_ingredient.ingredient
  end


  def to_collection_select
    "#{self.warehouse_types.name} - #{self.code} - #{self.name}"
  end

  def is_a_number?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
  end
end


  