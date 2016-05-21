class IngredientMedicamentRecipe < ActiveRecord::Base
  self.table_name = 'ingredients_medicaments_recipes'

  attr_protected :id

  belongs_to :ingredient
  belongs_to :medicament_recipe

  validates_presence_of :amount
  validates_numericality_of :amount
  validates_associated :ingredient, :medicament_recipe

  def validate_existence
    if IngredientMedicamentRecipe.where({:ingredient_id => self.ingredient_id, :medicament_recipe_id => self.medicament_recipe_id}).first
      errors.add_to_base("ingredient already exist")
    end
    return (errors.size > 0) ? false : true
  end
end
