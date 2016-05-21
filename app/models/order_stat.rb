class OrderStat < ActiveRecord::Base
  attr_protected :id

  belongs_to :order
  belongs_to :order_stat_type

  validates :order_id, :order_stat_type_id, presence: true
  validates :value, numericality: true
end
