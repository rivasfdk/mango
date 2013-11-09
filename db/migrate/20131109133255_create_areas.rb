class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.string :description, null: false
      t.timestamps
    end
  end
end
