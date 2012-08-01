class CreateMixingTimes < ActiveRecord::Migration
  def self.up
    create_table :mixing_times do |t|
      t.string :code, :null => false
      t.integer :wet_time, :null => false
      t.integer :dry_time, :null => false
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :mixing_times
  end
end
