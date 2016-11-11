class CreateWarehousesTypes < ActiveRecord::Migration
  def change
    create_table :warehouses_types do |t|
      t.string :name, :null => false

      t.timestamps
    end
  end
end