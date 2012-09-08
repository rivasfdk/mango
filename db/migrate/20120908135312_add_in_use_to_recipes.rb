class AddInUseToRecipes < ActiveRecord::Migration
  def self.up
    add_column :recipes, :in_use, :boolean, :default => true
  end

  def self.down
    remove_column :recipes, :in_use
  end
end
