class RemoveWarehouses < ActiveRecord::Migration
  def self.up
    drop_table :warehouses
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
