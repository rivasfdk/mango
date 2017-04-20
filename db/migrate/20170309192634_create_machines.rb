class CreateMachines < ActiveRecord::Migration
  def change
    create_table :machines do |t|
      t.references :location, index: true, foreign_key: true
      t.string :code, :null => false
      t.string :name, :null => false
      t.float :hours, :default=> 0

      t.timestamps
    end
  end
end
