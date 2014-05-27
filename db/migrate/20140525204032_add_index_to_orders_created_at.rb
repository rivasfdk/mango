class AddIndexToOrdersCreatedAt < ActiveRecord::Migration
  def change
    add_index :orders, :created_at
  end
end
