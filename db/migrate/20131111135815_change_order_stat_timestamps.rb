class ChangeOrderStatTimestamps < ActiveRecord::Migration
  def up
    change_column :orders_stats, :created_at, :int
    OrderStat.connection.execute 'UPDATE orders_stats SET created_at = UNIX_TIMESTAMP(updated_at)'
    add_index :orders_stats, :created_at
  end

  def down
    remove_index :orders_stats, :created_at
    change_column :orders_stats, :created_at, :timestamp
    OrderStat.connection.execute 'UPDATE orders_stats SET created_at = updated_at'
  end
end
