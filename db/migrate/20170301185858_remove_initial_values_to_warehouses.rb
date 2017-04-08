class RemoveInitialValuesToWarehouses < ActiveRecord::Migration
  def change
    remove_column :warehouses, :content_id, :integer
    remove_column :warehouses, :content_type, :boolean
  end
end
