class CreateLotsParametersTypes < ActiveRecord::Migration
  def change
    create_table :lots_parameters_types do |t|
      t.string :name, :null => false
      t.float :default_value
      t.timestamps
    end
  end
end
