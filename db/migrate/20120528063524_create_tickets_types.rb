class CreateTicketsTypes < ActiveRecord::Migration
  def self.up
    create_table :tickets_types do |t|
      t.string :code, :null=>false
      t.string :description, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :tickets_types
  end
end
