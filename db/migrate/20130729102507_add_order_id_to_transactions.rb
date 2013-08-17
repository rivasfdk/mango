include MigrationHelper
class AddOrderIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :order_id, :integer
    add_foreign_key :transactions, 'order_id', :orders
    add_index :transactions, :order_id
  end
end