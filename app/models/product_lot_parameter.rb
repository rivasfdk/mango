class ProductLotParameter < ActiveRecord::Base
  belongs_to :product_lot_parameter_list
  belongs_to :product_lot_parameter_type

  validates_presence_of :value, :product_lot_parameter_list, :product_lot_parameter_type
  validates_uniqueness_of :product_lot_parameter_type_id, :scope => :product_lot_parameter_list_id
  validates_numericality_of :value, :allow_nil => true
end
