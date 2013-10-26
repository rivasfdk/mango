class AddFactoryToHopperLots < ActiveRecord::Migration
  def change
    add_column :hoppers_lots, :factory, :boolean, :default => false, :null => false
  end
end
