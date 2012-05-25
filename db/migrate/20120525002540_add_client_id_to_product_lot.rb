class AddClientIdToProductLot < ActiveRecord::Migration
  def self.up
    add_column :products_lots, :client_id, :integer
  end

  def self.down
    remove_column :products_lots, :client_id
  end
end
