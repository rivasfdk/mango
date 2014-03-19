class LotParameterType < ActiveRecord::Base
  has_many :lot_parameters
  has_many :ingredient_parameter_type_ranges

  validates :name, :code, presence: true
  validates :name, :code, uniqueness: true
  validates :default_value, numericality: {allow_nil: true}

  after_create :update_all_lot_parameters_lists

  def update_all_lot_parameters_lists
    LotParameterList.all.each do |pl|
      parameter = pl.lot_parameters.new
      parameter.lot_parameter_type = self
      parameter.value = self.default_value
      parameter.save
    end
    unless self.is_string
      Ingredient.all.each do |i|
        iptr = self.ingredient_parameter_type_ranges.new
        iptr.ingredient_id = i.id
        iptr.save
      end
    end
  end
end
