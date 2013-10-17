class Ingredient < ActiveRecord::Base
  has_many :ingredient_recipe
  has_many :ingredient_medicament_recipe
  has_many :lot
  belongs_to :base_unit
  has_many :ingredient_parameter_type_ranges

  accepts_nested_attributes_for :ingredient_parameter_type_ranges

  validates_uniqueness_of :code
  validates_presence_of :name, :code
  validates_length_of :code, :name, :within => 3..40

  def to_collection_select
    "#{self.code} - #{self.name}"
  end

  def generate_parameter_type_ranges
    LotParameterType.all.each do |pt|
      r = pt.ingredient_parameter_type_ranges.new
      r.ingredient_id = self.id
      r.save
    end
  end
end
