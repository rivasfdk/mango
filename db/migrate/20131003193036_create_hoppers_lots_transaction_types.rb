class CreateHoppersLotsTransactionTypes < ActiveRecord::Migration
  def change
    create_table :hoppers_lots_transaction_types do |t|
      t.string :code, :null=>false
      t.string :description, :null=>false
      t.string :sign, :null=>false
      t.timestamps
    end
  end
end
