class AddCodeToOrderStatType < ActiveRecord::Migration
  def change
    add_column :orders_stats_types, :code, :string, null: false
  end
end
