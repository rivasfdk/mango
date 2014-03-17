class AddRealAmountToBatchHopperLot < ActiveRecord::Migration
  def change
    add_column :batch_hoppers_lots, :real_amount, :float
  end
end
