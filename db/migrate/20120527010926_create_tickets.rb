require 'migration_helper'

class CreateTickets < ActiveRecord::Migration
extend MigrationHelper
  def self.up
    create_table :tickets do |t|
      t.references :truck
      t.references :driver
      t.integer :number
      t.boolean :open, :default => true
      t.float :incoming_weight
      t.float :outgoing_weight
      t.float :provider_weight
      t.integer :provider_document_number
      t.timestamp :incoming_date
      t.timestamp :outgoing_date
      t.string :comment
      t.timestamps
    end
    add_foreign_key :tickets, 'truck_id', :trucks
    add_foreign_key :tickets, 'driver_id', :drivers
  end

  def self.down
    drop_table :tickets
  end
end
