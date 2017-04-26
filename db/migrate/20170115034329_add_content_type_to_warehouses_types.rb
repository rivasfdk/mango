class AddContentTypeToWarehousesTypes < ActiveRecord::Migration
  def change
    add_column :warehouses_types, :content_type, :boolean
  end
end