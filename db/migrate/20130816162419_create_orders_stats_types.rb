class CreateOrdersStatsTypes < ActiveRecord::Migration
  def change
    create_table :orders_stats_types do |t|
      t.string :description, :null => false
      t.timestamps
    end
  end
end
