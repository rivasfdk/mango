class AddClientIdToLot < ActiveRecord::Migration
  def self.up
    add_column :lots, :client_id, :integer
  end

  def self.down
    remove_column :lots, :client_id
  end
end
