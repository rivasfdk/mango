require 'migration_helper'

class CreateAlarms < ActiveRecord::Migration
extend MigrationHelper
  def self.up
    create_table :alarms do |t|
      t.references :order
      t.timestamp :date
      t.string :description
      t.timestamps
    end
    add_foreign_key 'alarms', 'order_id', 'orders'
  end

  def self.down
    drop_table :alarms
  end
end
