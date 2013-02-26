class RemoveCodeFromAlarmTypes < ActiveRecord::Migration
  def self.up
    remove_column :alarm_types, :code
  end

  def self.down
    add_column :alarm_types, :code, :string, :default => '0'
  end
end
