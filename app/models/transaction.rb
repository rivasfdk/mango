class Transaction < ActiveRecord::Base
  belongs_to :transaction_type
  belongs_to :warehouse
  belongs_to :user
  belongs_to :client
  belongs_to :ticket

  validates_presence_of :transaction_type_id, :warehouse_id, :amount, :user_id
  validates_numericality_of :amount
  validates_numericality_of :sacks, :sack_weight, :allow_nil => true
  
  before_save :create_code, :set_date
  before_save :do_stock_update
  after_destroy :undo_stock_update

  def self.get_no_processed
    Transaction.find :all, :conditions=>['processed_in_stock = 0']
  end

  def process
    transaction do
      self.processed_in_stock = 1
      unless self.save
        logger.error(self.errors.inspect)
        raise StandardError, 'Problem reprocessing transaction'
      end
    end
  end

  private

  def get_sign
    transaction_type = TransactionType.find(self.transaction_type_id)
    return transaction_type.sign
  end

  def do_stock_update
    if get_sign == '+'
      increase_stock
    else
      decrease_stock
    end
  end

  def undo_stock_update
    if get_sign == '-'
      increase_stock
    else
      decrease_stock
    end
  end

  def create_code
    unless self.id
      last = Transaction.last
      if last.nil?
        self.code = '00000001'
      else
        self.code = last.code.succ
      end
    end
  end

  def set_date
    unless self.id
      self.date = Date.today
    end
  end

  def increase_stock
    warehouse = Warehouse.get(self.warehouse.id)
    warehouse.stock += self.amount
    warehouse.save
    self.stock_after = warehouse.stock
  end

  def decrease_stock
    warehouse = Warehouse.get(self.warehouse.id)
    warehouse.stock -= self.amount
    warehouse.save
    self.stock_after = warehouse.stock
  end
end
