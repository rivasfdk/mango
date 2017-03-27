class AddCodeAndSackToWarehousesTypes < ActiveRecord::Migration
  def change
    add_column :warehouses_types, :code, :string
    add_column :warehouses_types, :sack, :boolean
  end
end
