class CreateTicketsOrder < ActiveRecord::Migration
  def change
    create_table :tickets_order do |t|
      t.string :code
      t.boolean :order_type
      t.integer :client_id
      t.integer :document_type_id
      t.string :document_number
      t.boolean :closed

      t.timestamps
    end
  end
end
