class Ticket < ActiveRecord::Base
  belongs_to :truck
  belongs_to :driver
  belongs_to :ticket_type
  belongs_to :user
  belongs_to :client

  has_many :transactions
  accepts_nested_attributes_for :transactions, allow_destroy: true, reject_if: lambda { |t| t[:content_id].blank? }

  validates_presence_of :truck_id, :driver_id, :ticket_type_id, :incoming_weight
  validates_numericality_of :incoming_weight, :greater_than => 0
  validates_numericality_of :outgoing_weight, :allow_nil => true, :greater_than => 0
  validates_numericality_of :provider_weight, :allow_nil => true
  before_save :generate_number, if: :new_record?
  before_validation :set_transaction_attributes

  def set_transaction_attributes
    self.transactions.each do |t|
      
    end
  end

  def generate_number
    ticket_number = TicketNumber.first
    self.number = ticket_number.number.succ
    self.open = true
    ticket_number.number = self.number
    ticket_number.save
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

  def self.search(params)
    tickets = Ticket.includes({ticket_type: {}, driver: {}, truck: {carrier: {}}})
    tickets = tickets.where(number: params[:number]) if params[:number].present?
    tickets = tickets.where('tickets.incoming_date >= ?', Date.parse(params[:start_date])) if params[:start_date].present?
    tickets = tickets.where('tickets.outgoing_date <= ?', Date.parse(params[:end_date]) + 1.day) if params[:end_date].present?
    tickets = tickets.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    tickets = tickets.where(trucks: {carrier_id: params[:carrier_id]}) if params[:carrier_id].present?
    tickets = tickets.order('number DESC')
    tickets.paginate page: params[:page], per_page: params[:per_page]
  end
end