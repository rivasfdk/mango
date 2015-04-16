class Transaction < ActiveRecord::Base
  belongs_to :transaction_type
  belongs_to :user
  belongs_to :client
  belongs_to :ticket
  belongs_to :order

  validates :transaction_type_id, :amount, :user_id, :content_type, :content_id, presence: true
  validates :amount, numericality: true
  validates :sacks, :sack_weight, numericality: {allow_nil: true}

  before_create :update_stock
  after_destroy :update_transactions

  def update_transactions
    old_stock_after = self.stock_after
    new_stock_after = 0

    previous_transaction = Transaction.where(['id < ? and content_type = ? and content_id = ?',
      self.id, self.content_type, self.content_id]).order('id desc').first

    if self.destroyed?
      unless previous_transaction.nil?
        new_stock_after = previous_transaction.stock_after
      end
    else
      actual_amount = self.get_sign == '+' ? self.amount : -1 * self.amount
      if previous_transaction.nil?
        new_stock_after = actual_amount
      else
        new_stock_after = previous_transaction.stock_after + actual_amount
      end
      self.update_column(:stock_after, new_stock_after)
    end

    diff = new_stock_after - old_stock_after

    pending_transactions = Transaction.where(['id > ? and content_type = ? and content_id = ?',
      self.id, self.content_type, self.content_id])
      .order('id asc')
    unless pending_transactions.empty?
      new_stock_after = pending_transactions.last.stock_after + diff
      pending_transactions.update_all(['stock_after = stock_after + ?', diff])
    end

    lot = self.content_type == 1 ? Lot.find(self.content_id) : ProductLot.find(self.content_id)
    lot.update_column(:stock, new_stock_after)
  end

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
                            .round(4)
      Lot.where(id: self.content_id)
         .update_all(stock: self.stock_after, updated_at: Time.now)
      Ingredient.find(self.get_content.id).save
    else
      self.stock_after = ProductLot.where(id: self.content_id)
                                   .pluck(:stock)
                                   .first + actual_amount
                                   .round(4)
      ProductLot.where(id: self.content_id)
                .update_all(stock: stock_after, updated_at: Time.now)
    end
  end
end
