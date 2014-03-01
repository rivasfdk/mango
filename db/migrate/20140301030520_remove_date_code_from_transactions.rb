class RemoveDateCodeFromTransactions < ActiveRecord::Migration
  def up
    remove_column :transactions, :code
    remove_column :transactions, :date
  end

  def down
  	add_column :transactions, :code, :string, default: 0, null: false
  	add_column :transactions, :date, :date, default: Date.now, null: false
  end
end
