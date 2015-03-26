class AddInUseToProductLots < ActiveRecord::Migration
  def change
  	add_column :products_lots, :in_use, :boolean, default: true
  end
end
