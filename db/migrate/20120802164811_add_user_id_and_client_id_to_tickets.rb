include MigrationHelper

class AddUserIdAndClientIdToTickets < ActiveRecord::Migration
  def self.up
    add_column :tickets, :user_id, :integer
    add_foreign_key :tickets, 'user_id', :users
    add_column :tickets, :client_id, :integer
    add_foreign_key :tickets, 'client_id', :clients
  end

  def self.down
    drop_foreign_key :tickets, 'user_id'
    remove_column :tickets, :user_id
    drop_foreign_key :tickets, 'client_id'
    remove_column :tickets, :client_id
  end
end
