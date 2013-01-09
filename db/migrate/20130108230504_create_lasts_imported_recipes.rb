class CreateLastsImportedRecipes < ActiveRecord::Migration
  def self.up
    create_table :lasts_imported_recipes do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :lasts_imported_recipes
  end
end
