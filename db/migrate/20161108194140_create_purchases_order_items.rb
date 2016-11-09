class CreatePurchasesOrderItems < ActiveRecord::Migration
  def change
    create_table :purchases_order_items do |t|
      t.integer :id_purchase_order
      t.integer :id_ingredient
      t.integer :position
      t.integer :quantity
      t.boolean :sack
      t.float :total_weight

      t.timestamps
    end
  end
end
