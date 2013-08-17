class OrderStatType < ActiveRecord::Base
  has_many :order_stats

  validates_presence_of :description
end
