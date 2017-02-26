class AddRemainingToTicketOrderItems < ActiveRecord::Migration
  def change
    add_column :tickets_order_items, :remaining, :real
  end
end
