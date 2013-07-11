class MedicamentRecipe < ActiveRecord::Base
  has_many :ingredient_medicament_recipe, :dependent => :destroy
  has_many :order
  
  validates_uniqueness_of :code
  validates_presence_of :name, :code
  validates_length_of :name, :within => 3..40

  def is_associated?()
    Order.where(:medicament_recipe_id => self.id).any?
  end

  def get_total
    total = 0
    ingredients = IngredientMedicamentRecipe.where(:medicament_recipe_id => self.id)
    ingredients.each do |i|
      total+= i.amount
    end
    return total
  end
end
