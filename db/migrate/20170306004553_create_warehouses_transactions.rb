class CreateWarehousesTransactions < ActiveRecord::Migration
  def change
    create_table :warehouses_transactions do |t|
      t.integer :transaction_type_id
      t.integer :warehouse_id
      t.float :amount
      t.float :stock_after
      t.integer :lot_id
      t.boolean :content_type
      t.integer :user_id

      t.timestamps
    end
  end
end
