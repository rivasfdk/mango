class Alarm < ActiveRecord::Base
  belongs_to :order
  belongs_to :alarm_type
  validates_presence_of :order_id, :description, :date, :alarm_type
end
