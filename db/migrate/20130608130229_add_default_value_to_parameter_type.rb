class AddDefaultValueToParameterType < ActiveRecord::Migration
  def self.up
    add_column :parameters_types, :default_value, :float
    ParameterType.all.each do |pt|
      pt.default_value = 100
      pt.save
    end
    change_column :parameters_types, :default_value, :float, :null => false
  end

  def self.down
    remove_column :parameters_types, :default_value
  end
end
