class CreateTicketsNumbers < ActiveRecord::Migration
  def self.up
    create_table :tickets_numbers do |t|
      t.string :number, :default => '0000000001'
      t.timestamps
    end
  end

  def self.down
    drop_table :tickets_numbers
  end
end
