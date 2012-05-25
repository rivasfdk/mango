class AddActiveToProductsLots < ActiveRecord::Migration
  def self.up
    add_column :products_lots, :active, :boolean, :default => true
  end

  def self.down
    remove_column :products_lots, :active
  end
end
