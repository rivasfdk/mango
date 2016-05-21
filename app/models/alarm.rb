class Alarm < ActiveRecord::Base
  attr_protected :id

  belongs_to :order
  belongs_to :alarm_type
  validates :order_id, :description, :date, :alarm_type, presence: true

  def self.create_from_scada(params)
    order_id = Order.where(code: params[:order_code]).pluck(:id).first
    return unless order_id
    Alarm.create alarm_type_id: params[:alarm_type_id], order_id: order_id, description: params[:description], date: Time.now
  end
end
