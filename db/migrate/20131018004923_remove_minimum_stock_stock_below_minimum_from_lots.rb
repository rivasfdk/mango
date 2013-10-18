class RemoveMinimumStockStockBelowMinimumFromLots < ActiveRecord::Migration
  def up
    remove_column :lots, :minimal_stock
    remove_column :lots, :stock_below_minimal
  end

  def down
    add_column :lots, :minimal_stock, :float, :default => 0, :null => false
    add_column :lots, :stock_below_minimal, :boolean, :default => false, :null => false
  end
end
