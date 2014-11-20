class AddRecipeTypeIdToRecipes < ActiveRecord::Migration
  def change
    add_column :recipes, :type_id, :integer, default: 0
    add_index :recipes, :type_id
  end
end
