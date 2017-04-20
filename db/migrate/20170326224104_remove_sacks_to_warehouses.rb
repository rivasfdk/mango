class RemoveSacksToWarehouses < ActiveRecord::Migration
  def change
    remove_column :warehouses, :sacks, :boolean
  end
end
