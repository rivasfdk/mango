include MigrationHelper

class AddAreaToOrderStatType < ActiveRecord::Migration
  def up
    add_column :orders_stats_types, :area_id, :integer
    add_foreign_key :orders_stats_types, :area_id, :areas
  end

  def down
    drop_foreign_key :orders_stats_types, :area_id
    remove_column :orders_stats_types, :area_id
  end
end
