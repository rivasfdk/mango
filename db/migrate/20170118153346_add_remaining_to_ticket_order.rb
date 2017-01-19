class AddRemainingToTicketOrder < ActiveRecord::Migration
  def change
    add_column :tickets_order, :remaining, :float
  end
end
