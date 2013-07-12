class AddIndexToOrderCode < ActiveRecord::Migration
  def change
    add_index :orders, :code
  end
end
