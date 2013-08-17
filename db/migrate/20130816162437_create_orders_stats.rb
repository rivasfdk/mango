include MigrationHelper
class CreateOrdersStats < ActiveRecord::Migration
  def change
    create_table :orders_stats do |t|
      t.references :order, :null => false
      t.references :order_stat_type, :null => false
      t.float :value, :null => false
      t.timestamps
    end
    add_foreign_key 'orders_stats', 'order_id', 'orders'
    add_foreign_key 'orders_stats', 'order_stat_type_id', 'orders_stats'
  end
end
