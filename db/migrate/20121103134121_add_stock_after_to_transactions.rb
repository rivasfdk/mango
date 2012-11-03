class AddStockAfterToTransactions < ActiveRecord::Migration
  def self.up
    add_column :transactions, :stock_after, :float
  end

  def self.down
    remove_column :transactions, :stock_after
  end
end
