class ProductParameterTypeRange < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_lot_parameter_type

  validates_presence_of :product, :product_lot_parameter_type
  validates_numericality_of :max, :allow_nil => true
  validates_numericality_of :min, :less_than_or_equal_to => :max, :allow_nil => true
end
