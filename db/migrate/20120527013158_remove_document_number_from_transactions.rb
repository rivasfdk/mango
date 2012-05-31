class RemoveDocumentNumberFromTransactions < ActiveRecord::Migration
  def self.up
    remove_column :transactions, :document_number
  end

  def self.down
    add_column :transactions, :document_number, :string
  end
end
