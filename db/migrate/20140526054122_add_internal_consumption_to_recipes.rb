class AddInternalConsumptionToRecipes < ActiveRecord::Migration
  def change
    add_column :recipes, :internal_consumption, :boolean, default: false
  end
end
