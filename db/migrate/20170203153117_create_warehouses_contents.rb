class CreateWarehousesContents < ActiveRecord::Migration
  def change
    create_table :warehouses_contents do |t|
      t.integer :warehouse_id
      t.boolean :content_type
      t.integer :content_id
      t.float :stock

      t.timestamps
    end
  end
end
