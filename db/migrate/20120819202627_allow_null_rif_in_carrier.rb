class AllowNullRifInCarrier < ActiveRecord::Migration
  def self.up
    change_column :carriers, :rif, :string, :null => true
  end

  def self.down
    change_column :carriers, :rif, :string, :null => false
  end
end
