class CreateParametersLists < ActiveRecord::Migration
  def self.up
    create_table :parameters_lists do |t|
      t.string :recipe_code, :null => false
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :parameters_lists
  end
end
