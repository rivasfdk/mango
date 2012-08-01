class ChangeProviderDocumentNumberTypeInTickets < ActiveRecord::Migration
  def self.up
    change_column :tickets, :provider_document_number, :string
  end

  def self.down
    change_column :tickets, :provider_document_number, :integer
  end
end
