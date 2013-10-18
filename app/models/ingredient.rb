class Ingredient < ActiveRecord::Base
  has_many :ingredient_recipe
  has_many :ingredient_medicament_recipe
  has_many :lot
  belongs_to :base_unit
  has_many :ingredient_parameter_type_ranges

  accepts_nested_attributes_for :ingredient_parameter_type_ranges

  before_save :check_stock

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

  def check_stock
    lots = Lot.where(:ingredient_id => self.id)
    stock = 0
    lots.each do |lot|
      stock += lot.stock
    end
    self.stock_below_minimum = stock < self.minimum_stock
    true
  end
end
