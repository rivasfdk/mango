class AddActiveToLots < ActiveRecord::Migration
  def self.up
    add_column :lots, :active, :boolean, :default => true
  end

  def self.down
    remove_column :lots, :active
  end
end
