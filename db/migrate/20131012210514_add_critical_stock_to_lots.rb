class AddCriticalStockToLots < ActiveRecord::Migration
  def change
    add_column :lots, :minimal_stock, :float, :default => 100
    add_column :lots, :stock_below_minimal, :boolean, :default => false
  end
end
