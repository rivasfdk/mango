class AddMinimumStockStockBelowMinimalToIngredients < ActiveRecord::Migration
  def change
    add_column :ingredients, :minimum_stock, :float, :default => 0, :null => false
    add_column :ingredients, :stock_below_minimum, :boolean, :default => false, :null => false
  end
end
