class CreateScales < ActiveRecord::Migration
  def change
    create_table :scales do |t|
      t.string :name, :null => false
      t.float :maximum_weight, :null => false
      t.float :minimum_weight, :null => false
      t.timestamps
    end
  end
end
