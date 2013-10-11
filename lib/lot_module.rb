module LotModule
  def recalculate
    stock = 0
    content_type = self.is_a?(Lot) ? 1 : 2
    transactions = Transaction.where({:content_id => self.id, :content_type => content_type})
    transactions.each do |t|
      puts "#{t.transaction_type.sign}#{t.amount}"
      stock += ("#{t.transaction_type.sign}#{t.amount}".to_f)
      if t.processed_in_stock == 0
        # Avoid triggering after_save do_stock_update callback
        ActiveRecord::Base.connection.update("UPDATE transactions SET processed_in_stock = 1 WHERE id = #{t.id}")
      end
      # Avoid triggering after_save do_stock_update callback
      ActiveRecord::Base.connection.update("UPDATE transactions SET stock_after = #{stock} WHERE id = #{t.id}")
    end
    self.stock = stock
    unless self.save
      logger.error(self.errors.inspect)
      raise StandardError, 'Problem updating lot stock'
      puts "Error"
    end
  end

  def adjust(amount, user_id, comment)
    diff = self.stock - amount
    transaction = Transaction.new
    transaction.content_id = self.id
    transaction.content_type = self.is_a?(Lot) ? 1 : 2
    transaction.amount = diff.abs
    transaction.comment = comment
    transaction.user_id = user_id
    if diff > 0
      transaction.transaction_type_id = 3 #SA-AJU
    else
      transaction.transaction_type_id = 2 #EN-AJU
    end
    transaction.processed_in_stock = 1
    transaction.save
  end
end
