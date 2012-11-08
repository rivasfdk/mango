class AddActiveToWarehouses < ActiveRecord::Migration
  def self.up
    add_column :warehouses, :active, :boolean, :default => true
  end

  def self.down
    remove_column :warehouses, :active
  end
end
