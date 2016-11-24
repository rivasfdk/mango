class CreateSalesOrderItems < ActiveRecord::Migration
  def change
    create_table :sales_order_items do |t|
      t.integer :sale_order_id
      t.integer :position
      t.boolean :content_type
      t.integer :content_id
      t.boolean :sack
      t.integer :quantity
      t.float :total_wheight

      t.timestamps
    end
  end
end
