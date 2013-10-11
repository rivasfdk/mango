class AddStockToHopperLots < ActiveRecord::Migration
  def change
    add_column :hoppers_lots, :stock, :float, :default => 0
  end
end
