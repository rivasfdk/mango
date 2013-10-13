class AddStockBelowMinimumToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :stock_below_minimum, :boolean, :default => false
    hoppers_lots = HopperLot.includes({:hopper => {}, :lot => {}}).where(:active => true)
    hoppers_lots.each do |hl|
      hl.check_hopper_stock
    end
  end
  def down
    remove_column :hoppers, :stock_below_minimum
  end
end
