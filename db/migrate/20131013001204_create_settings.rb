class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.float :hopper_minimum_level, :null => false, :default => 10
      t.timestamps
    end
  end
end
