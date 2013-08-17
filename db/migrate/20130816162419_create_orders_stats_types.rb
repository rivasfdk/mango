class CreateOrdersStatsTypes < ActiveRecord::Migration
  def change
    create_table :orders_stats_types do |t|
      t.string :type, :null => false
      t.timestamps
    end
  end
end
