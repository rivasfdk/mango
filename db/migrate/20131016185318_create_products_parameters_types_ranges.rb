include MigrationHelper

class CreateProductsParametersTypesRanges < ActiveRecord::Migration
  def change
    create_table :products_parameters_types_ranges do |t|
      t.references :product, :null => false
      t.references :product_lot_parameter_type, :null => false
      t.float :max
      t.float :min
      t.timestamps
    end
    add_foreign_key 'products_parameters_types_ranges', 'product_id', 'products'
    add_foreign_key 'products_parameters_types_ranges', 'product_lot_parameter_type_id', 'products_lots_parameters_types'
  end

  def down
    drop_table :products_parameters_types_ranges
  end
end
