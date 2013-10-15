class LotParameterType < ActiveRecord::Base
  has_many :lot_parameters

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :default_value, :allow_nil => true

  after_create :update_all_lot_parameters_lists

  def update_all_lot_parameters_lists
    LotParameterList.all.each do |pl|
      parameter = pl.lot_parameters.new
      parameter.lot_parameter_type = self
      parameter.value = self.default_value
      parameter.save
    end
  end
end
