class LotParameterList < ActiveRecord::Base
  has_many :lot_parameters, :dependent => :destroy
  belongs_to :lot

  validates_presence_of :lot

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
    self.lot_parameters.each do |lp|
      range = IngredientParameterTypeRange.where(:lot_parameter_type_id => lp.lot_parameter_type_id,
                                                 :ingredient_id => self.lot.ingredient_id).first 
      unless range.nil?
        parameters << {
          "name" => lp.lot_parameter_type.name,
          "value" => lp.value,
          "unit" => lp.lot_parameter_type.unit,
          "max" => range.max,
          "min" => range.min
        }
      else
        parameters << {
          :type => lp.lot_parameter_type.name,
          :value => lp.value,
          :max => nil,
          :min => nil        
        }
      end
    end
    parameters
  end
end
