include MigrationHelper
class CreateHoppersLotsTransaction < ActiveRecord::Migration
  def up
    create_table :hoppers_lots_transaction do |t|
      t.references :hopper_lot_transaction_type, :null => false
      t.references :hopper_lot, :null => false
      t.references :user, :null => false
      t.string :code, :null => false
      t.date :date, :null => false
      t.float :amount, :null => false
      t.float :stock_after, :null => false
      t.string :comment
      t.timestamps
    end
    add_foreign_key :hoppers_lots_transaction, :hopper_lot_transaction_type_id, :hoppers_lots_transaction_types
    add_foreign_key :hoppers_lots_transaction, :hopper_lot_id, :hoppers_lots
    add_foreign_key :hoppers_lots_transaction, :user_id, :users
  end

  def down
    drop_foreign_key :hoppers_lots_transaction, :hopper_lot_transaction_type_id
    drop_foreign_key :hoppers_lots_transaction, :hopper_lot_id
    drop_foreign_key :hoppers_lots_transaction, :user_id
    drop_table :hoppers_lots_transaction
  end
end
