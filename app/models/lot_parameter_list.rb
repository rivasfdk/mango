class LotParameterList < ActiveRecord::Base
  attr_protected :id

  has_many :lot_parameters, :dependent => :destroy
  belongs_to :lot

  validates :lot, presence: true

  accepts_nested_attributes_for :lot_parameters

  after_create :generate_lot_parameters

  def generate_lot_parameters
    LotParameterType.all.each do |pt|
      lot_parameter = self.lot_parameters.new
      lot_parameter.lot_parameter_type = pt
      lot_parameter.value = pt.default_value
      lot_parameter.save
    end
  end

  def parameters_with_range
    parameters = []
    self.lot_parameters
      .includes(:lot_parameter_type)
      .each do |lp|
        range = IngredientParameterTypeRange
          .where(lot_parameter_type_id: lp.lot_parameter_type_id,
                 ingredient_id: self.lot.ingredient_id).first
        parameters << {
          "name" => lp.lot_parameter_type.name,
          "value" => lp.lot_parameter_type.is_string ? lp.string_value : lp.value,
          "unit" => lp.lot_parameter_type.unit,
          "max" => range.nil? ? nil : range.max,
          "min" => range.nil? ? nil : range.min
        }
      end
    parameters
  end
end
