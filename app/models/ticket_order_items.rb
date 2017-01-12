class TicketOrderItems < ActiveRecord::Base
  attr_protected :id

  belongs_to :ticket_orders

end
