module LotModule
  def recalculate
    stock = 0
    content_type = self.is_a?(Lot) ? 1 : 2
    transactions = Transaction.includes(:transaction_type)
                              .where(content_id: self.id,
                                     content_type: content_type)
    transactions.each do |t|
      stock += t.transaction_type
                .sign == "+" ? t.amount : -1 * t.amount
      stock = stock.round(2)
      t.update_column(:stock_after, stock)
    end
    self.update_column(:stock, stock)
  end

  def adjust(amount, user_id, comment)
    diff = self.stock - amount
    Transaction.create content_id: self.id,
                       content_type: self.is_a?(Lot) ? 1 : 2,
                       transaction_type_id: diff > 0 ? 3 : 2,
                       amount: diff.abs,
                       comment: comment,
                       user_id: user_id
  end
end
