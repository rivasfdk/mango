class AddNewValuesToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :port1, :boolean
    add_column :settings, :port2, :boolean
  end
end
