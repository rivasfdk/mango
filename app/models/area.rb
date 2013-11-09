class Area < ActiveRecord::Base
  has_many :orders_areas
  has_many :orders_stats_types
  validates :description, presence: true
end
