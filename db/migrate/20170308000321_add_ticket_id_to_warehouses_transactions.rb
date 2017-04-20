class AddTicketIdToWarehousesTransactions < ActiveRecord::Migration
  def change
    add_column :warehouses_transactions, :ticket_id, :integer
  end
end
