class CreateTicketsOrderItems < ActiveRecord::Migration
  def change
    create_table :tickets_order_items do |t|
      t.integer :ticket_order_id
      t.integer :position
      t.boolean :content_type
      t.integer :content_id
      t.boolean :sack
      t.integer :quantity
      t.float :total_weight

      t.timestamps
    end
  end
end
