class Ticket < ActiveRecord::Base
  has_many :transactions
  belongs_to :truck
  belongs_to :driver
  belongs_to :ticket_type
  
  accepts_nested_attributes_for :transactions
  
  validates_presence_of :truck_id, :driver_id, :ticket_type_id, :incoming_weight, :provider_weight, :provider_document_number, :incoming_date
  validates_numericality_of :incoming_weight, :provider_weight, :provider_document_number, :greater_than => 0
  validates_uniqueness_of :provider_document_number
  before_save :generate_number

  def generate_number
    unless self.id
      ticket = TicketNumber.first
      self.number = ticket.number.succ
      self.open = true
      ticket.number = self.number
      ticket.save
    end
  end
  
  def close
    puts "Herp"
  end

  def get_gross_weight
    if self.ticket_type_id == 1 # Reception ticket
      return incoming_weight
    else # Dispatch ticket
      return outgoing_weight.nil? ? -1 : outgoing_weight
    end
  end

  def get_tare_weight
    if self.ticket_type_id == 1 # Reception ticket
      return outgoing_weight.nil? ? -1 : outgoing_weight
    else # Dispatch ticket
      return incoming_weight
    end

  end

  def get_net_weight
    if self.ticket_type_id == 1 # Reception ticket
      return outgoing_weight.nil? ? -1 : incoming_weight - outgoing_weight
    else # Dispatch ticket
      return outgoing_weight.nil? ? -1 : outgoing_weight - incoming_weight
    end
  end
end
