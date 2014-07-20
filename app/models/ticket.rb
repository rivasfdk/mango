class Ticket < ActiveRecord::Base
  belongs_to :truck
  belongs_to :driver
  belongs_to :ticket_type
  belongs_to :user
  belongs_to :client

  has_many :transactions
  accepts_nested_attributes_for :transactions

  validates_presence_of :truck_id, :driver_id, :ticket_type_id, :incoming_weight
  validates_numericality_of :incoming_weight, :greater_than => 0
  validates_numericality_of :outgoing_weight, :allow_nil => true, :greater_than => 0
  validates_numericality_of :provider_weight, :allow_nil => true
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

  def self.search(number, page, per_page)
    if number and number != ""
      paginate :page => page,
               :per_page => per_page,
               :conditions => ['number = ?', number],
               :order => 'number DESC'
    else
      paginate :page => page, :per_page => per_page, :order => 'number DESC'
    end
  end
end
