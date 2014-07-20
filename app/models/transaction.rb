class Transaction < ActiveRecord::Base
  belongs_to :transaction_type
  belongs_to :user
  belongs_to :client
  belongs_to :ticket
  belongs_to :order

  validates :transaction_type_id, :amount, :user_id, :content_type, :content_id, presence: true
  validates :amount, numericality: true
  validates :sacks, :sack_weight, numericality: {allow_nil: true}

  before_save :update_stock

  def get_lot
    if self.content_type == 1
      Lot.find self.content_id
    else
      ProductLot.find self.content_id
    end
  end

  def get_content
    if self.content_type == 1
      self.get_lot.ingredient
    else
      self.get_lot.product
    end
  end

  def get_sign
    TransactionType.where(id: self.transaction_type_id).pluck(:sign).first
  end

  private

  def update_stock
    actual_amount = self.get_sign == '+' ? self.amount : -1 * self.amount
    if self.content_type == 1
      self.stock_after = Lot.where(id: self.content_id)
                            .pluck(:stock)
                            .first + actual_amount
                            .round(2)
      Lot.where(id: self.content_id)
         .update_all(stock: self.stock_after, updated_at: Time.now)
    else
      self.stock_after = ProductLot.where(id: self.content_id)
                                   .pluck(:stock)
                                   .first + actual_amount
                                   .round(2)
      ProductLot.where(id: self.content_id)
                .update_all(stock: stock_after, updated_at: Time.now)
    end
  end
end