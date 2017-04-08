class AddMainToWarehouses < ActiveRecord::Migration
  def change
    add_column :warehouses, :main, :boolean
  end
end
