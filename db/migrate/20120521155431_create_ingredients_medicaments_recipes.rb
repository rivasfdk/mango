include MigrationHelper

class CreateIngredientsMedicamentsRecipes < ActiveRecord::Migration
  def self.up
    create_table :ingredients_medicaments_recipes do |t|
      t.references :ingredient
      t.references :medicament_recipe
      t.float :amount, :null => false
      t.timestamps
    end
    add_foreign_key 'ingredients_medicaments_recipes', 'ingredient_id', 'ingredients'
    add_foreign_key 'ingredients_medicaments_recipes', 'medicament_recipe_id', 'medicaments_recipes'
  end

  def self.down
    drop_table :ingredients_medicaments_recipes
  end
end
