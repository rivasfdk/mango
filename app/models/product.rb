class Product < ActiveRecord::Base
  has_many :product_lot
  belongs_to :base_unit
  has_many :product_parameter_type_ranges

  validates_uniqueness_of :code
  validates_presence_of :name, :code
  validates_length_of :code, :name, :within => 3..40

  def generate_parameter_type_ranges
    ProductLotParameterType.all.each do |pt|
      r = pt.product_parameter_type_ranges.new
      r.product_id = self.id
      r.save
    end
  end
end
