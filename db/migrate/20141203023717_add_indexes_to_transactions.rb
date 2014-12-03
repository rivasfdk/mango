class AddIndexesToTransactions < ActiveRecord::Migration
  def change
    add_index :transactions, :created_at
    add_index :transactions, :content_id
    add_index :transactions, :content_type
  end
end
