class AddEmptyToLots < ActiveRecord::Migration
  def change
    add_column :lots, :empty, :boolean
  end
end
