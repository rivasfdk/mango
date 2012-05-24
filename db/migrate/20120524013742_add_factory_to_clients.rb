class AddFactoryToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :factory, :boolean, :default => false
  end

  def self.down
    remove_column :clients, :factory
  end
end
