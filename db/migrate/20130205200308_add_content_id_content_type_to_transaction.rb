class AddContentIdContentTypeToTransaction < ActiveRecord::Migration
  def self.up
    add_column :transactions, :content_id, :integer
    add_column :transactions, :content_type, :integer
  end

  def self.down
    remove_column :transactions, :content_id
    remove_column :transactions, :content_type
  end
end
