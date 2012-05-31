class AddTicketIdToTransactions < ActiveRecord::Migration
  def self.up
    add_column :transactions, :ticket_id, :integer
  end

  def self.down
    remove_column :transactions, :ticket_id
  end
end
