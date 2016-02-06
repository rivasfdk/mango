class TicketType < ActiveRecord::Base
  attr_protected :id

  has_many :tickets
end
