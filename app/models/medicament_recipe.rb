class MedicamentRecipe < ActiveRecord::Base
  attr_protected :id

  has_many :ingredient_medicament_recipe, :dependent => :destroy
  has_many :order

  validates_uniqueness_of :code
  validates_presence_of :name, :code
  validates_length_of :name, :within => 3..40

  accepts_nested_attributes_for :ingredient_medicament_recipe, allow_destroy: true, reject_if: lambda { |ir| t[:ingredient_id].blank? }

  def is_associated?()
    Order.where(:medicament_recipe_id => self.id).any?
  end

  def get_total
    ingredient_medicament_recipe.pluck(:amount).reduce { |total, amount| total + amount }
  end

  def to_collection_select
    return "#{self.name} - #{self.code}"
  end

end
