class ChangeTransactionStockAfterType < ActiveRecord::Migration
  def up
    change_column :transactions, :stock_after, :decimal, precision: 15, scale: 4
  end

  def down
    change_column :transactions, :stock_after, :float
  end
end
