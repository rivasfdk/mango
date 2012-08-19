class AddFrequentToDriversTrucksCarriers < ActiveRecord::Migration
  def self.up
    add_column :drivers, :frequent, :boolean, :default => true
    add_column :trucks, :frequent, :boolean, :default => true
    add_column :carriers, :frequent, :boolean, :default => true
  end

  def self.down
    remove_column :drivers, :frequent
    remove_column :trucks, :frequent
    remove_column :carriers, :frequent
  end
end
