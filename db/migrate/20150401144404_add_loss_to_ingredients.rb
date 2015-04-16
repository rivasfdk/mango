class AddLossToIngredients < ActiveRecord::Migration
  def change
    add_column :ingredients, :loss, :float, default: 0, null: false
  end
end
