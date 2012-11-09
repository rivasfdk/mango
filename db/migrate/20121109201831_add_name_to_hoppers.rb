class AddNameToHoppers < ActiveRecord::Migration
  def self.up
    add_column :hoppers, :name, :string, :default => " "
  end

  def self.down
    remove_column :hoppers, :name
  end
end
