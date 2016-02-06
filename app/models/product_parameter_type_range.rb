class ProductParameterTypeRange < ActiveRecord::Base
  attr_protected :id

  belongs_to :product
  belongs_to :product_lot_parameter_type

  validates_presence_of :product, :product_lot_parameter_type
  validates :max, numericality: {allow_nil: true}
  validates :min, numericality: {less_than_or_equal_to: :max, allow_nil: true}
end
