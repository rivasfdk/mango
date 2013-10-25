class BatchHopperLot < ActiveRecord::Base
  belongs_to :hopper_lot
  belongs_to :batch

  validates_presence_of :batch, :hopper_lot, :amount
  validates_uniqueness_of :hopper_lot_id, :scope => [:batch_id]
  validates_numericality_of :amount, :greater_than_or_equal_to => 0

  after_save :update_batch_end_date

  def generate_transaction(user_id)
    t = Transaction.new
    t.order_id = self.batch.order_id
    t.transaction_type_id = 1 # SA-CSM
    t.content_type = 1
    t.content_id = self.hopper_lot.lot_id
    t.amount = self.amount
    t.user_id = user_id
    t.save
  end

  def generate_hopper_transaction(user_id)
    unless self.hopper_lot.hopper.scale.not_weighed
      hlt = self.hopper_lot.hopper_lot_transactions.new
      hlt.hopper_lot_transaction_type_id = 2 # SA-CSM
      hlt.amount = self.amount
      hlt.user_id = user_id
      hlt.save
    end
  end

  private

  def update_batch_end_date
    self.batch.update_column(end_date, self.created_at)
  end
end
