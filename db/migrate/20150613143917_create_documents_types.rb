class CreateDocumentsTypes < ActiveRecord::Migration
  def change
    create_table :documents_types do |t|
      t.string :name
      t.timestamps
    end
  end
end
