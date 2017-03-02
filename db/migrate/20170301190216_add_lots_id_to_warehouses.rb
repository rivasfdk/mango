class AddLotsIdToWarehouses < ActiveRecord::Migration
  def change
    add_column :warehouses, :lot_id, :integer
    add_column :warehouses, :product_lot_id, :integer
  end
end
