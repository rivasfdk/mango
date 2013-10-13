class AddDensityToLots < ActiveRecord::Migration
  def up
    add_column :lots, :density, :float, :null => false, :default => 1
  end
end
