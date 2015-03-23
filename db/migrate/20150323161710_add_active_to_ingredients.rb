class AddActiveToIngredients < ActiveRecord::Migration
  def change
  	add_column :ingredients, :active, :boolean, default: true, null: false
  end
end
