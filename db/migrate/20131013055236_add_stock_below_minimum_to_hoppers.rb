class AddStockBelowMinimumToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :stock_below_minimum, :boolean, :default => false
  end
end
