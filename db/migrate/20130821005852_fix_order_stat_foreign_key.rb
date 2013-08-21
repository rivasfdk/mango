include MigrationHelper
class FixOrderStatForeignKey < ActiveRecord::Migration
  def up
    drop_foreign_key 'orders_stats', 'order_stat_type_id'
    add_foreign_key 'orders_stats', 'order_stat_type_id', 'orders_stats_types'
  end

  def down
    drop_foreign_key 'orders_stats', 'order_stat_type_id'
    add_foreign_key 'orders_stats', 'order_stat_type_id', 'orders_stats'
  end
end
