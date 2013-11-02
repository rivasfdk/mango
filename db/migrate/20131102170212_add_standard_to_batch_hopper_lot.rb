class AddStandardToBatchHopperLot < ActiveRecord::Migration
  def change
    add_column :batch_hoppers_lots, :standard_amount, :float, default: 0, null: false
  end
end
