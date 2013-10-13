class CreateLotsParametersLists < ActiveRecord::Migration
  def change
    create_table :lots_parameters_lists do |t|
      t.references :lot
      t.timestamps
    end
  end
end
