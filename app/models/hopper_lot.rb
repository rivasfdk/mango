class HopperLot < ActiveRecord::Base
  belongs_to :hopper
  belongs_to :lot
  has_many :batch_hopper_lot
  has_many :hopper_lot_transactions

  accepts_nested_attributes_for :hopper_lot_transactions

  validates_presence_of :hopper, :lot

  before_save :update_active, :if => :new_record?
  after_save :update_main_hopper, :check_hopper_stock

  def update_active
    HopperLot.update_all('active = false', ['hopper_id = ?', self.hopper_id])
    self.active = true
  end
  
  def check_hopper_stock
    level = ((self.stock / self.lot.density) / self.hopper.capacity * 100).round(2)
    self.hopper.stock_below_minimum = self.hopper.scale.not_weighed ? false : level < Settings.first.hopper_minimum_level
    self.hopper.save
  end

  def update_main_hopper
    #Set hopper.main to true if there is no main hopper for the same ingredient
    hoppers = Hopper.find :all,
                          :include => {:hopper_lot => [:lot]},
                          :conditions => ['hoppers_lots.active = true and lots.ingredient_id = ? and hoppers_lots.hopper_id != ? and hoppers.main = true', self.lot.ingredient_id, self.hopper_id]
    self.hopper.main = hoppers.empty?
    self.hopper.save

    #If there is no main hopper for the previous ingredient after updating the hopper
    #set hopper.main to true to the first hopper with the previous ingredient (if any)
    previous_hopper_lot = HopperLot.find :first,
                                         :include => [:lot],
                                         :conditions => ['active = false and hopper_id = ?', self.hopper_id],
                                         :order => ['id desc']
    unless previous_hopper_lot.nil?
      hoppers = Hopper.find :all,
                            :include => {:hopper_lot => [:lot]},
                            :conditions => ['hoppers_lots.active = true and lots.ingredient_id = ?', previous_hopper_lot.lot.ingredient_id],
                            :order => ['hoppers.scale_id, hoppers.number ASC']
      unless hoppers.empty?
        if hoppers.select {|hopper| hopper.main == true}.empty?
          hoppers.first.main = true
          hoppers.first.save
        end
      end
    end
  end
end
