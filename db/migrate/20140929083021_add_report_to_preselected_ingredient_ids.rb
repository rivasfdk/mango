class AddReportToPreselectedIngredientIds < ActiveRecord::Migration
  def change
    add_column :preselected_ingredients_id, :report, :string, default: 'production_and_ingredient_distribution'
  end
end
