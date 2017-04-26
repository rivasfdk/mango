class AddWarehouseIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :warehouse_id, :integer
  end
end
