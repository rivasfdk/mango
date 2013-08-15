include MigrationHelper
class RemoveMixingTimes < ActiveRecord::Migration
  def change
    drop_foreign_key :recipes, :mixing_time_id 
    remove_column :recipes, :mixing_time_id
    drop_table :mixing_times
  end
end
