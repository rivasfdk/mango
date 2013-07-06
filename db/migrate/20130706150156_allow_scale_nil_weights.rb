class AllowScaleNilWeights < ActiveRecord::Migration
  def up
    change_column :scales, :minimum_weight, :float, :null => true
    change_column :scales, :maximum_weight, :float, :null => true
  end

  def down
    change_column :scales, :minimum_weight, :float, :null => false
    change_column :scales, :maximum_weight, :float, :null => false
  end
end
