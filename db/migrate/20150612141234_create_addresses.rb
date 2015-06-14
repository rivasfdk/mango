class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.references :client, null: false
      t.string :address, null: false
      t.timestamps
    end
  end
end
