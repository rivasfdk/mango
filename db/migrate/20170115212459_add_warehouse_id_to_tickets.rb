class AddWarehouseIdToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :warehouse_id, :integer
  end
end
