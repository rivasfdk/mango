class Product < ActiveRecord::Base
  has_many :product_lot
  has_many :recipes
  belongs_to :base_unit
  has_many :product_parameter_type_ranges

  accepts_nested_attributes_for :product_parameter_type_ranges

  validates :code, uniqueness: true
  validates :name, :code, presence: true
  validates :code, :name, length: {within: 3..40}

  def to_collection_select
    "#{self.code} - #{self.name}"
  end

  def generate_parameter_type_ranges
    ProductLotParameterType.all.each do |pt|
      r = pt.product_parameter_type_ranges.new
      r.product_id = self.id
      r.save
    end
  end
end
