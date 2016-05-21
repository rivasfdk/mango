class Area < ActiveRecord::Base
  attr_protected :id

  has_many :orders_areas
  has_many :orders_stats_types
  validates :description, presence: true
end
