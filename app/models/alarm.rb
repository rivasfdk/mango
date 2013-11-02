class Alarm < ActiveRecord::Base
  belongs_to :order
  belongs_to :alarm_type
  validates :order_id, :description, :date, :alarm_type, presence: true
end
