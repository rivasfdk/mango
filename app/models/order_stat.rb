class OrderStat < ActiveRecord::Base
  belongs_to :order
  belongs_to :order_stat_type

  validates_presence_of :order, :order_stat_type
  validates_numericality_of :value
end
