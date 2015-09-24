class Ticket < ActiveRecord::Base
  belongs_to :truck
  belongs_to :driver
  belongs_to :ticket_type
  belongs_to :user
  belongs_to :client
  belongs_to :document_type

  has_many :transactions
  accepts_nested_attributes_for :transactions, allow_destroy: true, reject_if: lambda { |t| t[:content_id].blank? }

  validates_presence_of :truck_id, :driver_id, :ticket_type_id, :incoming_weight
  validates_numericality_of :incoming_weight, greater_than: 0
  validates_numericality_of :outgoing_weight, allow_nil: true, greater_than: 0
  validates_numericality_of :provider_weight, allow_nil: true
  before_create :generate_number
  before_create :set_notified

  STATES = {
    0 => {name: 'Abiertos', condition: 'tickets.open = TRUE'},
    1 => {name: 'Por notificar', condition: 'tickets.open = FALSE AND tickets.notified = FALSE'},
    2 => {name: 'Notificados', condition: 'tickets.open = FALSE AND tickets.notified = TRUE'},
  }

  def self.get_states
    STATES.collect { |k, v| [v[:name], k] }
  end

  def generate_number
    ticket_number = TicketNumber.first
    self.number = ticket_number.number.succ
    self.open = true
    ticket_number.number = self.number
    ticket_number.save
  end

  def set_notified
    self.notified = !is_mango_feature_available("notifications")
    true
  end

  def notify
    return false if self.notified
    update_column(:notified, true)
    self.transactions.each do |t|
      new_t = t.dup
      t.delete
      new_t.notified = true
      new_t.save
    end
    true
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

  def get_perc_diff

  end

  def self.search(params)
    transactions = Ticket.base_search
    transactions = transactions.where('tickets.number = ?', params[:number]) if params[:number].present?
    transactions = transactions.where('tickets.incoming_date >= ?', Date.parse(params[:start_date])) if params[:start_date].present?
    transactions = transactions.where('tickets.outgoing_date <= ?', Date.parse(params[:end_date]) + 1.day) if params[:end_date].present?
    transactions = transactions.where('tickets.driver_id = ?', params[:driver_id]) if params[:driver_id].present?
    transactions = transactions.where('tickets.provider_document_number LIKE ?', "%#{params[:document_number]}%") if params[:document_number].present?
    transactions = transactions.where(STATES[params[:state_id].to_i][:condition]) if params[:state_id].present?
    transactions = transactions.where('tickets.ticket_type_id = ?', params[:ticket_type_id]) if params[:ticket_type_id].present?
    transactions = transactions.where('ingredients.id = ? and content_type = ?', params[:content_id], params[:content_type]) if params[:content_id].present?
    transactions = transactions
      .order('tickets.number desc')
      .limit(WillPaginate.per_page)
    transactions = transactions.offset((params[:page].to_i - 1) * WillPaginate.per_page) if params[:page].present?

    paginated_transactions = transactions.paginate(page: params[:page])

    tickets = transactions.each_with_object(Hash.new {|hash, key| hash[key] = []}) do |transaction, tickets|
      tickets[transaction[:ticket_id]] <<= transaction
    end
    [tickets, paginated_transactions]
  end

  def self.base_search
    Ticket
      .joins({ticket_type: {}, document_type: {}, driver: {}, client: {}, transactions: {}})
      .joins('left outer join lots on transactions.content_id = lots.id and transactions.content_type = 1')
      .joins('left outer join products_lots on transactions.content_id = products_lots.id and transactions.content_type = 2')
      .joins('left outer join ingredients on lots.ingredient_id = ingredients.id')
      .joins('left outer join products on products_lots.product_id = products.id')
      .select('
        tickets.id as ticket_id,
        tickets.number as ticket_number,
        tickets.incoming_date as ticket_incoming_date,
        tickets.outgoing_date as ticket_outgoing_date,
        tickets.incoming_weight as ticket_incoming_weight,
        tickets.outgoing_weight as ticket_outgoing_weight,
        abs(tickets.incoming_weight - tickets.outgoing_weight) as net_weight,
        tickets.comment as ticket_comment,
        tickets.address as ticket_address,
        tickets.provider_document_number as document_number,
        tickets.provider_weight as provider_weight,
        tickets.open as ticket_open,
        tickets.notified as ticket_notified,
        tickets_types.code as ticket_type,
        clients.ci_rif as client_cirif,
        clients.name as client_name,
        drivers.ci as driver_ci,
        drivers.name as driver_name,
        documents_types.name as document_type,
        transactions.amount as transaction_amount,
        transactions.sack as transaction_sack,
        transactions.sacks as transaction_sacks,
        transactions.sack_weight as transaction_sack_weight,
        coalesce(lots.code, products_lots.code) as lot_code,
        coalesce(lots.comment, products_lots.comment) as lot_comment,
        coalesce(ingredients.code, products.code) as content_code,
        coalesce(ingredients.name, products.name) as content_name
      ')
  end
end
