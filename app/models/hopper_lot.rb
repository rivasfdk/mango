class HopperLot < ActiveRecord::Base
  belongs_to :hopper
  belongs_to :lot
  has_many :batch_hopper_lot

  validates_associated :hopper, :lot

  before_save :update_active

  def update_active
    HopperLot.update_all('active = false', "hopper_id = #{self.hopper_id}")
    self.active = true
  end
end
