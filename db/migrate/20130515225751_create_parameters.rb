require 'migration_helper'

class CreateParameters < ActiveRecord::Migration
extend MigrationHelper
  def self.up
    create_table :parameters do |t|
      t.references :parameter_list
      t.references :parameter_type
      t.float :value, :null => false
      t.timestamps
    end
    add_foreign_key 'parameters', 'parameter_list_id', 'parameters_lists'
    add_foreign_key 'parameters', 'parameter_type_id', 'parameters_types'
  end

  def self.down
    drop_table :parameters
  end
end
