class CreateProductsLotsParametersLists < ActiveRecord::Migration
  def change
    create_table :products_lots_parameters_lists do |t|
      t.references :product_lot
      t.timestamps
    end
  end
end
