class CreatePurchasesOrder < ActiveRecord::Migration
  def change
    create_table :purchases_order do |t|
      t.string :code
      t.integer :id_client
      t.boolean :closed

      t.timestamps
    end
  end
end
