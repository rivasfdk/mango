class AddEmptyToProductsLots < ActiveRecord::Migration
  def change
    add_column :products_lots, :empty, :boolean
  end
end
