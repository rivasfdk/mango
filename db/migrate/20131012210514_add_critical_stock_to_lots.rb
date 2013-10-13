class AddCriticalStockToLots < ActiveRecord::Migration
  def change
    add_column :lots, :minimal_stock, :float, :default => 100
    add_column :lots, :stock_below_minimal, :boolean, :default => false
    Lot.all.each do |lot|
      if lot.stock < lot.minimal_stock
        lot.stock_below_minimal = true
        lot.save
      end
    end
  end
end
