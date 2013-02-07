class RemoveWarehouseType < ActiveRecord::Migration
  def self.up
    drop_table :warehouses_types
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
