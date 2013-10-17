include MigrationHelper

class CreateProductsLotsParameters < ActiveRecord::Migration
  def up
    create_table :products_lots_parameters do |t|
      t.references :product_lot_parameter_list, :null => false
      t.references :product_lot_parameter_type, :null => false
      t.float :value
      t.timestamps
    end
    add_foreign_key 'products_lots_parameters', 'product_lot_parameter_list_id', 'products_lots_parameters_lists'
    add_foreign_key 'products_lots_parameters', 'product_lot_parameter_type_id', 'products_lots_parameters_types'
  end

  def down
    drop_table :products_lots_parameters
  end
end
