include MigrationHelper

class AddProductToRecipe < ActiveRecord::Migration
  def up
    add_column :recipes, :product_id, :integer
    Recipe.update_all product_id: Product.first.id
    change_column :recipes, :product_id, :integer, null: false
    add_foreign_key :recipes, :product_id, :products
    add_index :recipes, :product_id
  end

  def down
    remove_index :recipes, :product_id
    drop_foreign_key :recipes, :product_id
    remove_column :recipes, :product_id
  end
end