class AddDateCloseToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :completed_at, :datetime
    Order.find_each do |order|
      order.completed_at = order.created_at if order.completed
      order.save!(:validate => false)
    end
  end
end
