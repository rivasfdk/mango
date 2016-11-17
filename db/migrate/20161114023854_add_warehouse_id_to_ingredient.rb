class AddWarehouseIdToIngredient < ActiveRecord::Migration
  def self.up
    add_column :ingredients, :warehouse_id, :integer
  end

  def self.down
    remove_column :ingredients, :warehouse_id
  end
end
