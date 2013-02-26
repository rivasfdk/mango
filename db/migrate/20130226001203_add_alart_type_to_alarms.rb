class AddAlartTypeToAlarms < ActiveRecord::Migration
  def self.up
    add_column :alarms, :alarm_type_id, :integer, :default => 1
  end

  def self.down
    remove_column :alarms, :alarm_type_id
  end
end
