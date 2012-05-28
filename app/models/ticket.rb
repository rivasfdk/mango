class Ticket < ActiveRecord::Base
  has_one :transaction
  belongs_to :truck
  belongs_to :driver
  belongs_to :ticket_type
  
  validates_presence_of :truck_id, :driver_id, :ticket_type_id, :incoming_weight, :provider_weight, :provider_document_number, :incoming_date
  validates_numericality_of :incoming_weight, :provider_weight, :provider_document_number, :greater_than => 0
  validates_uniqueness_of :provider_document_number
  before_save :generate_number

  def generate_number
    ticket = TicketNumber.first
    self.number = ticket.number.succ
    self.open = true
    ticket.number = self.number
    ticket.save
  end
  
  def close
    puts "Herp"
  end
end
