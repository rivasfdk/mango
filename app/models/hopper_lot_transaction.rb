class HopperLotTransaction < ActiveRecord::Base
  attr_protected :id

  belongs_to :hopper_lot_transaction_type
  belongs_to :hopper_lot
  belongs_to :user

  validates_presence_of :hopper_lot_transaction_type, :amount, :user, :hopper_lot
  validates_numericality_of :amount

  before_save :create_code, :set_date
  before_save :do_stock_update
  after_save :check_for_negative_stock

  private

  def create_code
    if self.new_record?
      last = HopperLotTransaction.last
      if last.nil?
        self.code = '00000001'
      else
        self.code = last.code.succ
      end
    end
  end

  def set_date
    if self.new_record?
      self.date = Date.today
    end
  end

  def get_sign
    HopperLotTransactionType.find(self.hopper_lot_transaction_type_id).sign
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

  def check_for_negative_stock
    if self.stock_after < 0
      self.hopper_lot.stock = 0
      self.hopper_lot.save
      HopperLotTransaction.skip_callback(:save, :before, :do_stock_update)
      hlt = HopperLotTransaction.new
      hlt.hopper_lot_transaction_type_id = 3
      hlt.hopper_lot_id = self.hopper_lot_id
      hlt.user_id = self.user_id
      hlt.amount = -1 * self.stock_after
      hlt.stock_after = 0
      hlt.comment = "Ajuste a 0 por existencia negativa"
      hlt.save
      HopperLotTransaction.set_callback(:save, :before, :do_stock_update)
    end
  end
end
