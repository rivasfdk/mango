class AddSackSupportToTransactions < ActiveRecord::Migration
  def self.up
    add_column :transactions, :sack, :boolean, :default => false
    add_column :transactions, :sack_weight, :integer
    add_column :transactions, :sacks, :integer
  end

  def self.down
    remove_column :transactions, :sack
    remove_column :transactions, :sack_weight
    remove_column :transactions, :sacks
  end
end
