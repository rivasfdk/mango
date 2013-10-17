include MigrationHelper

class CreateLotsParameters < ActiveRecord::Migration
  def up
    create_table :lots_parameters do |t|
      t.references :lot_parameter_list, :null => false
      t.references :lot_parameter_type, :null => false
      t.float :value
      t.timestamps
    end
    add_foreign_key 'lots_parameters', 'lot_parameter_list_id', 'lots_parameters_lists'
    add_foreign_key 'lots_parameters', 'lot_parameter_type_id', 'lots_parameters_types'
  end

  def down
    drop_table :lots_parameters
  end
end