include MigrationHelper

class CreateOrdersAreas < ActiveRecord::Migration
  def up
    create_table :orders_areas do |t|
      t.references :order, null: false
      t.references :area, null: false
      t.boolean :active, default: false, null: false
      t.timestamps
    end
    add_foreign_key :orders_areas, :order_id, :orders
    add_foreign_key :orders_areas, :area_id, :areas
  end

  def down
    drop_table :orders_areas
  end
end
