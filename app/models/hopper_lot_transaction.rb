class HopperLotTransaction < ActiveRecord::Base
  belongs_to :hopper_lot_transaction_type
  belongs_to :hopper_lot
  belongs_to :user

  validates_presence_of :hopper_lot_transaction_type, :amount, :user, :hopper_lot
  validates_numericality_of :amount

  before_save :create_code, :set_date
  before_save :do_stock_update
  
  private

  def create_code
    unless self.id
      last = HopperLotTransaction.last
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

  def get_sign
    hltt = HopperLotTransactionType.find(self.hopper_lot_transaction_type_id)
    hltt.sign
  end

  def do_stock_update
    if get_sign == '+'
      increase_stock
    else
      decrease_stock
    end
  end

  def increase_stock
    hopper_lot = self.hopper_lot
    hopper_lot.stock += self.amount
    hopper_lot.save
    self.stock_after = hopper_lot.stock
  end

  def decrease_stock
    hopper_lot = self.hopper_lot
    hopper_lot.stock -= self.amount
    hopper_lot.save
    self.stock_after = hopper_lot.stock
  end
end
