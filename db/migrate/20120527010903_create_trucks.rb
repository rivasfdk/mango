require 'migration_helper'

class CreateTrucks < ActiveRecord::Migration
extend MigrationHelper
  def self.up
    create_table :trucks do |t|
      t.references :carrier
      t.string :license_plate, :null => false
      t.timestamps
    end
    add_foreign_key :trucks, 'carrier_id', :carriers
  end

  def self.down
    drop_table :trucks
  end
end
