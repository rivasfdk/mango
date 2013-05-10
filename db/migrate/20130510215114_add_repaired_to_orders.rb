class AddRepairedToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :repaired, :boolean, :default => false
  end

  def self.down
    remove_column :orders, :repaired
  end
end
