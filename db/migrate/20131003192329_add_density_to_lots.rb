class AddDensityToLots < ActiveRecord::Migration
  def change
    add_column :lots, :density, :float
  end
end