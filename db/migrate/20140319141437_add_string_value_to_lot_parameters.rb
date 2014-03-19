class AddStringValueToLotParameters < ActiveRecord::Migration
  def change
    add_column :lots_parameters_types, :is_string, :boolean, default: false
    add_column :lots_parameters, :string_value, :string
    add_column :products_lots_parameters_types, :is_string, :boolean, default: false
    add_column :products_lots_parameters, :string_value, :string
  end
end
