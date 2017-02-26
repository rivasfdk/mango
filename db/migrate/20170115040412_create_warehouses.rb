class CreateWarehouses < ActiveRecord::Migration
  def change
    create_table :warehouses do |t|
      t.references :warehouse_types, index: true, foreign_key: true
      t.integer :content_id
      t.string :code, :null => false
      t.string :name, :null => false
      t.float :stock, :default=> 0
      t.float :size

      t.timestamps
    end
  end
end