class Truck < ActiveRecord::Base
  belongs_to :carrier
  has_many :tickets

  validates :license_plate, :carrier, presence: true
end
