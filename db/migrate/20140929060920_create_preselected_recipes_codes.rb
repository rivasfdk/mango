class CreatePreselectedRecipesCodes < ActiveRecord::Migration
  def change
    create_table :preselected_recipes_codes do |t|
      t.string :recipe_code
      t.integer :user_id
      t.timestamps
    end
  end
end
