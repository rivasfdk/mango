class AddInUseAttributeToModelIngredientLot < ActiveRecord::Migration
  def self.up
    add_column :lots, :in_use, :boolean, :default => true
  end

  def self.down
    remove_column :lots, :in_use
  end
end
