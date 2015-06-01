class AddNotifiedToTicketsAndTransactions < ActiveRecord::Migration
  def change
    add_column :tickets, :notified, :boolean, default: true
    add_column :transactions, :notified, :boolean, default: true
  end
end
