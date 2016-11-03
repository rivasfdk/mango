class CreateWarehousesTypes < ActiveRecord::Migration
  def change
    create_table :warehouses_types do |t|
      t.string :code, :null=>false
      t.string :description, :null=>false

      t.timestamps
    end
  end
end

