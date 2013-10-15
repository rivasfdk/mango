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
end
