class RemoveDateFromProductLots < ActiveRecord::Migration
  def change
    remove_column :products_lots, :date
  end
end
