class AddTicketIdIndexForTransactions < ActiveRecord::Migration
  def change
    add_index :transactions, :ticket_id
    add_index :tickets, :driver_id
  end
end
