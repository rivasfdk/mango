class ChangeLotsStockNumberType < ActiveRecord::Migration
  def up
    change_column :lots, :stock, :decimal, precision: 15, scale: 4, null: false, default: 0
    change_column :products_lots, :stock, :decimal, precision: 15, scale: 4, null: false, default: 0
  end

  def down
    change_column :lots, :stock, :float, null: false, default: 0
    change_column :products_lots, :stock, :float, null: false, default: 0
  end
end
