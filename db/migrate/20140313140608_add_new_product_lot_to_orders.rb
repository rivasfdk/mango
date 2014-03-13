class AddNewProductLotToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :create_product_lot, :boolean, default: false
  end
end
