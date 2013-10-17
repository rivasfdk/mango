class LotParameterType < ActiveRecord::Base
  has_many :lot_parameters
  has_many :ingredient_parameter_type_ranges

  validates_presence_of :name, :code
  validates_uniqueness_of :name, :code
  validates_numericality_of :default_value, :allow_nil => true

  after_create :update_all_lot_parameters_lists

  def update_all_lot_parameters_lists
    LotParameterList.all.each do |pl|
      parameter = pl.lot_parameters.new
      parameter.lot_parameter_type = self
      parameter.value = self.default_value
      parameter.save
    end
    Ingredient.all.each do |i|
      iptr = self.ingredient_parameter_type_ranges.new
      iptr.ingredient_id = i.id
      iptr.save
    end
  end
end
