include MigrationHelper

class CreateHoppersFactoryLots < ActiveRecord::Migration
  def up
    create_table :hoppers_factory_lots do |t|
      t.references :hopper_lot
      t.references :client
      t.references :lot
      t.timestamps
    end
    add_foreign_key 'hoppers_factory_lots', 'hopper_lot_id', 'hoppers_lots'
    add_foreign_key 'hoppers_factory_lots', 'client_id', 'clients'
    add_foreign_key 'hoppers_factory_lots', 'lot_id', 'lots'
  end

  def down
    drop_table :hoppers_factory_lots
  end
end
