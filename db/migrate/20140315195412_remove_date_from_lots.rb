class RemoveDateFromLots < ActiveRecord::Migration
  def change
    remove_column :lots, :date
  end
end
