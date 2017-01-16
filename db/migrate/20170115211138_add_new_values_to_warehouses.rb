class AddNewValuesToWarehouses < ActiveRecord::Migration
  def change
    add_column :warehouses, :content_type, :boolean
  end
end
