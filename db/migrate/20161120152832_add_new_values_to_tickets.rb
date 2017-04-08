class AddNewValuesToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :id_order, :integer
  end
end
