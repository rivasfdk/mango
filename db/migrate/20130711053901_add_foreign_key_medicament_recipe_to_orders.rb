include MigrationHelper

class AddForeignKeyMedicamentRecipeToOrders < ActiveRecord::Migration
  def up
    add_foreign_key :orders, 'medicament_recipe_id', :medicaments_recipes
  end
  def down
    drop_foreign_key :orders, 'medicament_recipe_id'
  end
end
