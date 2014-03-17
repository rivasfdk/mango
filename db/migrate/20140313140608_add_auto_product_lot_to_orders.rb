class AddAutoProductLotToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :auto_product_lot, :boolean, default: false
  end
end
