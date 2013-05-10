class AddRealProductionToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :real_production, :float
  end

  def self.down
    remove_column :orders, :real_production
  end
end
