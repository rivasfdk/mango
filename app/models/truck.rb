class Truck < ActiveRecord::Base
  belongs_to :carrier
  has_many :tickets
  
  validates_presence_of :license_plate
  validates_uniqueness_of :license_plate
end
