class ParameterList < ActiveRecord::Base
  attr_protected :id

  has_many :parameters, :dependent => :destroy
  has_many :orders

  validates_presence_of :recipe_code
  validate :recipe_code_uniqueness

  after_create :generate_parameters

  def self.find_by_recipe(recipe_code)
    ParameterList.includes({:parameters => {:parameter_type => {}}}).where({:recipe_code => recipe_code, :active => true}).first
  end

  def is_associated?
    self.orders.any?
  end

  private
  def generate_parameters
    ParameterType.all.each do |pt|
      parameter = self.parameters.new
      parameter.parameter_type = pt
      parameter.value = pt.default_value
      parameter.save
    end
  end

  def recipe_code_uniqueness
    if self.new_record? and ParameterList.where({:recipe_code => self.recipe_code, :active => true}).any?
      errors.add(:recipe_code, "ya tiene una lista de parametros asociada")
    end
  end
end
