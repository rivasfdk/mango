include MangoModule

class BatchHopperLot < ActiveRecord::Base
  attr_protected :id

  belongs_to :hopper_lot
  belongs_to :batch

  validates :batch, :hopper_lot, :amount, presence: true
  validates :hopper_lot_id, uniqueness: { scope: :batch_id }
  validates :amount, :standard_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :hopper_batch_uniqueness

  before_save :set_real_amount
  after_create :update_batch_end_date

  def hopper_batch_uniqueness
    bhls = BatchHopperLot.joins(:hopper_lot)
    bhls = bhls.where(['batch_hoppers_lots.id != ?', self.id]) unless self.new_record?
    bhls = bhls.where(['batch_hoppers_lots.batch_id = ? and hoppers_lots.hopper_id = ?', self.batch_id, self.hopper_lot.hopper_id])
    errors.add(:hopper_lot, 'Solo puede existir un único consumo por tolva por batche') if bhls.count != 0
  end

  def generate_transaction(user_id)
    return true if is_mango_feature_available("notifications")
    t = Transaction.new
    t.order_id = self.batch.order_id
    t.transaction_type_id = 1 # SA-CSM
    t.content_type = 1
    t.content_id = self.hopper_lot.lot_id
    if is_mango_feature_available("ingredient_loss")
      t.amount = (1 + self.hopper_lot.lot.ingredient.loss / 100) * self.amount
    else
      t.amount = self.amount
    end
    t.user_id = user_id
    t.save(validate: false)
  end

  def generate_hopper_transaction(user_id)
    unless self.hopper_lot.hopper.scale.not_weighed
      hlt = self.hopper_lot.hopper_lot_transactions.new
      hlt.hopper_lot_transaction_type_id = 2 # SA-CSM
      hlt.amount = self.amount
      hlt.user_id = user_id
      hlt.save(validate: false)
    end
  end

  def update_batch_end_date
    self.batch.update_column(:end_date, self.created_at)
  end

  def set_real_amount
    self.real_amount = self.amount
  end
end
