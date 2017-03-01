class AddCodeToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :code, :string
  end
end
