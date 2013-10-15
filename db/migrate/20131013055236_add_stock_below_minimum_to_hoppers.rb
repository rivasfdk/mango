class AddStockBelowMinimumToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :stock_below_minimum, :boolean, :default => false
    Settings.new(:hopper_minimum_level => 10).save if Settings.first.nil?
  end
  def down
    remove_column :hoppers, :stock_below_minimum
  end
end
