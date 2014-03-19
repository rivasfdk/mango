class ProductLotParameterType < ActiveRecord::Base
  has_many :product_lot_parameters
  has_many :product_parameter_type_ranges

  validates :name, :code, presence: true
  validates :name, :code, uniqueness: true
  validates :default_value, numericality: {allow_nil: true}

  after_create :update_all_product_lot_parameters_lists

  def update_all_product_lot_parameters_lists
    ProductLotParameterList.all.each do |pl|
      parameter = pl.product_lot_parameters.new
      parameter.product_lot_parameter_type = self
      parameter.value = self.default_value
      parameter.save
    end
    unless self.is_string
      Product.all.each do |p|
        pptr = self.product_parameter_type_ranges.new
        pptr.product_id = p.id
        pptr.save
      end
    end
  end
end
