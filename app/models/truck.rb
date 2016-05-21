class Truck < ActiveRecord::Base
  attr_protected :id

  belongs_to :carrier
  has_many :tickets

  validates :license_plate, :carrier, presence: true
  validates :license_plate, uniqueness: {if: :frequent, case_sensitive: false, scope: :frequent}

  def to_collection_select
    "#{self.license_plate} - #{self.carrier.name}"
  end
end
