class AddUnitAndCodeToLotParameterTypeProductLotParameterType < ActiveRecord::Migration
  def change
    add_column :lots_parameters_types, :unit, :string
    add_column :lots_parameters_types, :code, :string, :null => false
    add_column :products_lots_parameters_types, :unit, :string
    add_column :products_lots_parameters_types, :code, :string, :null => false
  end
end
