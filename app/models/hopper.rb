class Hopper < ActiveRecord::Base
  attr_protected :id

  belongs_to :scale
  has_many :hopper_lot
  validates :number, :name, :scale, :capacity, presence: true
  validates :name, uniqueness: true
  validates :number, uniqueness: {scope: :scale_id}, numericality: {only_integer: true, greater_than: 0}
  validates :capacity, numericality: {greater_than: 0}
  before_save :check_stock, unless: :new_record?

  def check_stock
    hopper_lot = current_hopper_lot
    level = ((hopper_lot.stock / hopper_lot.lot.density) / self.capacity * 100).round(2)
    self.stock_below_minimum = self.scale.not_weighed ? false : level < Settings.first.hopper_minimum_level
    true
  end

  def capacity_in_kg
    density = current_lot.density
    (capacity.present? and density.present?) ? capacity * density : 0
  end

  def capacity_in_kg_by_lot(lot_id)
    lot = Lot.find_by id: lot_id
    unless lot.nil?
      (capacity.present? and lot.density.present?) ? capacity * lot.density : 0
    else
      0
    end
  end

  def adjust(params, user_id)
    if is_a_number? params[:new_stock]
      new_stock = params[:new_stock].to_f
      capacity_in_kg = self.capacity_in_kg
      if new_stock < 0
        logger.debug("stock can't be negative")
        false
      elsif new_stock > capacity_in_kg
        logger.debug("stock exceeds capacity")
        false
      elsif
        hl = current_hopper_lot
        amount = new_stock - hl.stock
        hlt = current_hopper_lot.hopper_lot_transactions.new
        hlt.hopper_lot_transaction_type_id = amount > 0 ? 3 : 4
        hlt.amount = amount.abs
        hlt.user_id = user_id
        hlt.save
      end
    else
      false
    end
  end

  def change(params, user_id)
    if is_a_number? params[:amount]
      amount = params[:amount].to_f
      new_lot_id = params[:lot_id].to_i
      if current_lot.id == new_lot_id
        logger.debug("lot can't be the same")
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

  def fill(params, user_id)
    hopper_lot = current_hopper_lot
    if is_a_number? params[:amount]
      amount = params[:amount].to_f
      logger.debug("Stock: #{hopper_lot.stock}")
      logger.debug("Capacidad en Kg: #{capacity_in_kg}")
      if amount <= 0 or hopper_lot.stock + amount > capacity_in_kg
        return false
      end
      hlt = hopper_lot.hopper_lot_transactions.new
      hlt.hopper_lot_transaction_type_id = 1
      hlt.user_id = user_id
      hlt.amount = amount
      hlt.save
    else
      return false
    end
  end

  def is_full?
    chl = current_hopper_lot
    lot = chl.lot
    (capacity.present? and lot.density.present?) ? chl.stock >= capacity * lot.density : false
  end

  def current_lot
    hopper_lot = HopperLot.includes(:lot).where(hopper_id: self.id, active: true).first
    return hopper_lot.nil? ? nil : hopper_lot.lot
  end

  def current_hopper_lot
    HopperLot.includes(:lot, :hoppers_factory_lots).where(hopper_id: self.id, active: true).first
  end

  def set_as_main_hopper
    hoppers = Hopper.includes({hopper_lot: :lot}).where(['hoppers.id != ? and hoppers_lots.active = true and lots.ingredient_id = ?', self.id, self.current_lot.ingredient_id])
    unless hoppers.empty?
      Hopper.update_all('main = false', :id => hoppers.map {|hopper| hopper.id})
    end
    self.update_attributes(main: true)
  end

  def eliminate
    begin
      b = BatchHopperLot.includes(:hopper_lot).where({hoppers_lots: {hopper_id: self.id}})
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

  def self.find_actives(scale_id)
    actives = []
    hoppers_lots = HopperLot.includes({hopper: {}, lot: {ingredient: {}}}).where({active: true, hoppers: {scale_id: scale_id}}).order('hoppers.number ASC')
    hoppers_lots.each do |hl|
      stock_string = "#{hl.stock} Kg"
      unless hl.hopper.capacity.nil? or hl.lot.density.nil?
        stock_string = "#{hl.stock} Kg. (#{((hl.stock / hl.lot.density) / hl.hopper.capacity * 100).round(2)}%)"
      end
      actives << {
        :lot => hl,
        :hopper_id => hl.hopper_id,
        :number => hl.hopper.number,
        :name => hl.hopper.name,
        :main => hl.hopper.main,
        :stock_string => stock_string,
        :stock_below_minimum => hl.hopper.stock_below_minimum
      }
    end
    actives
  end

  def self.actives_to_select
    actives = []
    hoppers_lots = HopperLot.includes({hopper: {}, lot: {ingredient: {}}}).where({active: true}).order('hoppers.scale_id, hoppers.number ASC')
    hoppers_lots.each do |hl|
      actives << ["Tolva #{hl.hopper.name} - #{hl.lot.ingredient.name} (L: #{hl.lot.code})", hl.id]
    end
    return actives
  end

  def self.set_main_hoppers
    Hopper.update_all('main = false')
    main_hoppers = {}
    hoppers_lots = HopperLot.includes({hopper: {}, lot: {}}).where({active: true}).order('hoppers.scale_id, hoppers.number ASC')
    hoppers_lots.each do |hopper_lot|
      unless main_hoppers.has_key? hopper_lot.lot.ingredient_id
        main_hoppers[hopper_lot.lot.ingredient_id] = hopper_lot.hopper_id
      end
    end
    Hopper.update_all('main = true', id: main_hoppers.values)
  end

  def to_collection_select
    "#{self.scale.name} - #{self.number} - #{self.name}"
  end

  def is_a_number?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
  end
end
