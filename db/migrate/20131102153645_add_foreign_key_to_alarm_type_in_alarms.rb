include MigrationHelper

class AddForeignKeyToAlarmTypeInAlarms < ActiveRecord::Migration
  def up
    add_foreign_key :alarms, :alarm_type_id, :alarm_types
    add_index :alarms, :alarm_type_id
  end

  def down
    drop_foreign_key :alarms, :alarm_type_id
    remove_index :alarms, :alarm_type_id    
  end
end
