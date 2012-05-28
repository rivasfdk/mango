class CreateDrivers < ActiveRecord::Migration
  def self.up
    create_table :drivers do |t|
      t.string :name, :null => false
      t.string :ci, :null => false
      t.string :address
      t.string :tel1
      t.string :tel2
      t.timestamps
    end
  end

  def self.down
    drop_table :drivers
  end
end
