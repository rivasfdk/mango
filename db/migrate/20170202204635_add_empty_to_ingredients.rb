class AddEmptyToIngredients < ActiveRecord::Migration
  def change
    add_column :ingredients, :empty, :boolean
  end
end
