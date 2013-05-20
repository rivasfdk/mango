class ParameterList < ActiveRecord::Base
  has_many :parameters, :dependent => :destroy
  has_many :orders

  validates_presence_of :recipe_code
  validate :recipe_code_uniqueness

  def self.find_by_recipe(recipe_code)
    ParameterList.find(:first, :conditions => ['recipe_code = ? and active = true', recipe_code])
  end

  def is_associated?
    Order.where(:parameter_list_id => self.id).any?
  end

  private
  def recipe_code_uniqueness
    if self.new_record? and ParameterList.find(:first, :conditions => ['recipe_code = ? and active = true', self.recipe_code])
      errors.add(:recipe_code, "ya tiene una lista de parametros asociada")
    end
  end
end
