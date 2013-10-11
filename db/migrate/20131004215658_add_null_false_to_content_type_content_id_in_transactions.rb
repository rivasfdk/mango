class AddNullFalseToContentTypeContentIdInTransactions < ActiveRecord::Migration
  def up
    change_column :transactions, :content_type, :integer, :null => false
    change_column :transactions, :content_id, :integer, :null => false
  end
  def down
    change_column :transactions, :content_type, :integer, :null => true
    change_column :transactions, :content_id, :integer, :null => true
  end
end
