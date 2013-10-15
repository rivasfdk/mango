class AddIndexToHopperLotTransactionCreatedAt < ActiveRecord::Migration
  def change
    add_index :hoppers_lots_transaction, :created_at
  end
end
