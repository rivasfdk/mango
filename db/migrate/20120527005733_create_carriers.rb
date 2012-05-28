class CreateCarriers < ActiveRecord::Migration
  def self.up
    create_table :carriers do |t|
      t.string :code, :null => false
      t.string :rif, :null => false
      t.string :name, :null => false
      t.string :email
      t.string :address
      t.string :tel1
      t.string :tel2
      t.timestamps
    end
  end

  def self.down
    drop_table :carriers
  end
end
