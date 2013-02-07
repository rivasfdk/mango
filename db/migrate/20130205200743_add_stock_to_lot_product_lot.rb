class AddStockToLotProductLot < ActiveRecord::Migration
  def self.up
    add_column :lots, :stock, :float, :default => 0
    add_column :products_lots, :stock, :float, :default => 0
  end

  def self.down
    remove_column :lots, :stock
    remove_column :products_lots, :stock
  end
end
