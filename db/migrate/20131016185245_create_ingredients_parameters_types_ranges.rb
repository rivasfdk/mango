include MigrationHelper

class CreateIngredientsParametersTypesRanges < ActiveRecord::Migration
  def up
    create_table :ingredients_parameters_types_ranges do |t|
      t.references :ingredient, :null => false
      t.references :lot_parameter_type, :null => false
      t.float :max
      t.float :min
      t.timestamps
    end
    add_foreign_key 'ingredients_parameters_types_ranges', 'ingredient_id', 'ingredients', 'fk_ingredient_id'
    add_foreign_key 'ingredients_parameters_types_ranges', 'lot_parameter_type_id', 'lots_parameters_types', 'fk_lot_parameter_type_id'
  end

  def down
    drop_table :ingredients_parameters_types_ranges
  end
end
