class ProductLotParameterList < ActiveRecord::Base
  has_many :product_lot_parameters, :dependent => :destroy
  belongs_to :product_lot

  validates_presence_of :product_lot

  after_create :generate_product_lot_parameters

  def generate_product_lot_parameters
    ProductLotParameterType.all.each do |pt|
      product_lot_parameter = self.product_lot_parameters.new
      product_lot_parameter.product_lot_parameter_type = pt
      product_lot_parameter.value = pt.default_value
      product_lot_parameter.save
    end
  end
end
