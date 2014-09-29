class CreatePreselectedIngredientsId < ActiveRecord::Migration
  def change
    create_table :preselected_ingredients_id do |t|
      t.integer :ingredient_id
      t.integer :user_id
      t.timestamps
    end
  end
end
