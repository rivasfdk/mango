class AddClientIdToTransactions < ActiveRecord::Migration
  def self.up
    add_column :transactions, :client_id, :integer
  end

  def self.down
    remove_column :transactions, :client_id
  end
end
