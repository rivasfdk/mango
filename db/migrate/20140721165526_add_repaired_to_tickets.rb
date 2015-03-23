class AddRepairedToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :repaired, :boolean, default: false, null: false
  end
end
