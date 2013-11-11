class HopperLot < ActiveRecord::Base
  belongs_to :hopper
  belongs_to :lot
  has_many :batch_hopper_lot
  has_many :hopper_lot_transactions
  has_many :hoppers_factory_lots

  accepts_nested_attributes_for :hoppers_factory_lots

  validates :hopper, :lot, presence: true

  before_save :update_active, if: :new_record?, unless: :factory
  after_create :update_main_hopper, :update_factory_lots, unless: :factory
  after_save :check_hopper_stock, unless: :factory

  def update_active
    HopperLot.where(hopper_id: self.hopper_id).update_all(active: false)
    self.active = true
  end
  
  def check_hopper_stock
    level = ((self.stock / self.lot.density) / self.hopper.capacity * 100).round(2)
    self.hopper.stock_below_minimum = self.hopper.scale.not_weighed ? false : level < Settings.first.hopper_minimum_level
    self.hopper.save
  end

  def update_main_hopper
    #Set hopper.main to true if there is no main hopper for the same ingredient
    hoppers = Hopper.includes(:hopper_lot => {:lot => {}}).where(['hoppers_lots.active = true and lots.ingredient_id = ? and hoppers_lots.hopper_id != ? and hoppers.main = true', self.lot.ingredient_id, self.hopper_id])
    self.hopper.main = hoppers.empty?
    self.hopper.save

    #If there is no main hopper for the previous ingredient after updating the hopper
    #set hopper.main to true to the first hopper with the previous ingredient (if any)
    previous = previous_hopper_lot
    unless previous.nil?
      hoppers = Hopper.includes({:hopper_lot => [:lot]}).where(['hoppers_lots.active = true and lots.ingredient_id = ?', previous.lot.ingredient_id]).order('hoppers.scale_id, hoppers.number ASC')
      unless hoppers.empty?
        if hoppers.select {|hopper| hopper.main == true}.empty?
          hoppers.first.main = true
          hoppers.first.save
        end
      end
    end
  end

  def update_factory_lots
    previous = previous_hopper_lot
    unless previous.nil?
      previous.hoppers_factory_lots.each do |hfl|
        hfl.hopper_lot = self
        hfl.lot = Lot.where(:ingredient_id => self.lot.ingredient_id, :client_id => hfl.client_id, :active => true, :in_use => true).last unless previous.lot.ingredient_id == self.lot.ingredient_id
        hfl.save
      end
    end
  end

  def previous_hopper_lot
    HopperLot.includes(:lot, :hoppers_factory_lots).where(:active => false, :factory => false, :hopper_id => self.hopper_id).last
  end

  def generate_hoppers_factory_lots
    self.hoppers_factory_lots.delete_all
    Client.where(factory: true).each do |client|
      self.hoppers_factory_lots.create client_id: client.id
    end
  end
end
