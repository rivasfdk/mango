class Alarm < ActiveRecord::Base
  belongs_to :order
  validates_presence_of :order_id, :description, :date
end
