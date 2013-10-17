class ProductLotParameterType < ActiveRecord::Base
  has_many :product_lot_parameters
  has_many :product_parameter_type_ranges

  validates_presence_of :name, :code
  validates_uniqueness_of :name, :code
  validates_numericality_of :default_value, :allow_nil => true

  after_create :update_all_product_lot_parameters_lists

  def update_all_product_lot_parameters_lists
    ProductLotParameterList.all.each do |pl|
      parameter = pl.product_lot_parameters.new
      parameter.product_lot_parameter_type = self
      parameter.value = self.default_value
      parameter.save
    end
    Product.all.each do |p|
      pptr = self.product_parameter_type_ranges.new
      pptr.product_id = p.id
      pptr.save
    end
  end
end
