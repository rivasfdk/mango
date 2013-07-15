include MigrationHelper

class AddForeignKeyToParameterListInOrders < ActiveRecord::Migration
  def up
    add_foreign_key :orders, 'parameter_list_id', :parameters_lists
  end
  def down
    drop_foreign_key :orders, 'parameter_list_id'
  end
end
