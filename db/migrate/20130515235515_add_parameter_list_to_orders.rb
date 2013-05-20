class AddParameterListToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :parameter_list_id, :integer
  end

  def self.down
    remove_column :orders, :parameter_list_id
  end
end
