class AddNotifiedToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :notified, :boolean, default: true
  end
end
