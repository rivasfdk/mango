class ParameterType < ActiveRecord::Base
  attr_protected :id

  has_many :parameters

  validates_presence_of :name, :default_value
  validates_uniqueness_of :name

  after_create :update_all_parameters_lists

  def update_all_parameters_lists
    ParameterList.where(:active => true).each do |pl|
      parameter = pl.parameters.new
      parameter.parameter_type = self
      parameter.value = self.default_value
      parameter.save
    end
  end
end
