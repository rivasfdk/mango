class ChangeDataTypeForSackWeight < ActiveRecord::Migration
  def self.up
    change_column :transactions, :sack_weight, :float
  end

  def self.down
    change_column :transactions, :sack_weight, :integer
  end
end
