class AddTotalToLastImportedRecipe < ActiveRecord::Migration
  def self.up
    add_column :lasts_imported_recipes, :total_recipes, :integer, :default => 0
    add_column :lasts_imported_recipes, :imported_recipes, :integer, :default => 0
  end

  def self.down
    remove_column :lasts_imported_recipes, :total_recipes
    remove_column :lasts_imported_recipes, :imported_recipes
  end
end
