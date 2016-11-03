class WarehouseTypes < ActiveRecord::Base
 attr_protected :id

  belongs_to :warehouse

  validates :code, :descirption, presence: true
  validates :code, uniqueness: true
  validates :code, :description, length: {within: 3..40}
 
end
