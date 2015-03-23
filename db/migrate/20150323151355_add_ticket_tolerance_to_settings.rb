class AddTicketToleranceToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :ticket_reception_diff, :float, default: 0.5
    add_column :settings, :ticket_dispatch_diff, :float, default: 0.5
  end
end
