class AddManualIngomingOutgoingWeightToTickets < ActiveRecord::Migration
  def self.up
    add_column :tickets, :manual_incoming, :boolean, :default => false
    add_column :tickets, :manual_outgoing, :boolean, :default => false
  end

  def self.down
    remove_column :tickets, :manual_incoming
    remove_column :tickets, :manual_outgoing
  end
end
