class Truck < ActiveRecord::Base
  belongs_to :carrier
  has_many :tickets

  validates :license_plate, :carrier, presence: true

  def to_collection_select
    "#{self.license_plate} - #{self.carrier.name}"
  end
end
