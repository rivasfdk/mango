class AddEmptyToProducts < ActiveRecord::Migration
  def change
    add_column :products, :empty, :boolean
  end
end
