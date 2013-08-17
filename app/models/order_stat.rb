class OrderStat < ActiveRecord::Base
  belongs_to :order
  belongs_to :order_stat_type
end
