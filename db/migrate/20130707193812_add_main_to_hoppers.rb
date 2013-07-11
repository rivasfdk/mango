class AddMainToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :main, :boolean, :default => false
    Hopper.set_main_hoppers()
  end
end
