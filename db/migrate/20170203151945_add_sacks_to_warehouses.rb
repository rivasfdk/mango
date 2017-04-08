class AddSacksToWarehouses < ActiveRecord::Migration
  def change
    add_column :warehouses, :sacks, :boolean
  end
end
