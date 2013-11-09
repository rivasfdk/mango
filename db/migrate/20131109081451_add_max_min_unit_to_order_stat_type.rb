class AddMaxMinUnitToOrderStatType < ActiveRecord::Migration
  def change
    add_column :orders_stats_types, :min, :float
    add_column :orders_stats_types, :max, :float
    add_column :orders_stats_types, :unit, :string, limit: 20
  end
end
