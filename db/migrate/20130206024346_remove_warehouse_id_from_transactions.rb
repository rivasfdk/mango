class RemoveWarehouseIdFromTransactions < ActiveRecord::Migration
  def self.up
    remove_column :transactions, :warehouse_id
  end

  def self.down
    add_column :transactions, :warehouse_id, :integer, :null => false
  end
end
