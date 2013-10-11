class AddVolumeToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :capacity, :float, :default => 1000, :null => false
  end
end
