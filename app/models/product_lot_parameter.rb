class ProductLotParameter < ActiveRecord::Base
  attr_protected :id

  belongs_to :product_lot_parameter_list
  belongs_to :product_lot_parameter_type

  validates :product_lot_parameter_list, :product_lot_parameter_type,
            presence: true
  validates :product_lot_parameter_type_id,
            uniqueness: {scope: :product_lot_parameter_list_id}
  validates :value, numericality: {allow_nil: true}
end
