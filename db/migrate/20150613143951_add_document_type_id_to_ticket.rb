class AddDocumentTypeIdToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :document_type_id, :integer
  end
end
