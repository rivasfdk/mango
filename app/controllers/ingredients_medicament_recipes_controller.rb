# encoding: UTF-8

class IngredientsMedicamentRecipesController < ApplicationController
  def index
    @medicament_recipe = Recipe.find(params[:medicament_recipe_id], :include=>'ingredient_medicament_recipe')
    @ingredients = Ingredient.all
  end

  def create
    unless params[:ingredient_medicament_recipe][:code].blank?
      @medicament_recipe = MedicamentRecipe.find(params[:medicament_recipe_id], :include=>'ingredient_medicament_recipe')
      ingredient = Ingredient.where(code: params[:ingredient_medicament_recipe][:code]).first

      ingredient_medicament_recipe = IngredientMedicamentRecipe.new
      ingredient_medicament_recipe.ingredient = ingredient
      ingredient_medicament_recipe.medicament_recipe = @medicament_recipe
      ingredient_medicament_recipe.amount = params[:ingredient_medicament_recipe][:amount]

      if ingredient_medicament_recipe.valid?
        ingredient_medicament_recipe.save
        flash[:notice] = "Ingrediente agregado a la receta de medicamentos"
      else
        logger.error("No se pudo guardar el ingrediente: #{ingredient_medicament_recipe.errors.inspect}")
        flash[:notice] = "No se pudo guardar el ingrediente"
        flash[:type] = 'error'
      end
    else
      flash[:notice] = "Por favor seleccione un ingrediente válido"
      flash[:type] = 'error'
    end

    redirect_to edit_medicament_recipe_path(params[:medicament_recipe_id])
  end

  def destroy
    @ingredient_medicament_recipe = IngredientMedicamentRecipe.find params[:id]
    @ingredient_medicament_recipe.eliminate
    if @ingredient_medicament_recipe.errors.empty?
      flash[:notice] = "Ingrediente eliminado de la receta de medicamentos con éxito"
    else
      logger.error("Error eliminando ingrediente de la receta de medicamentos: #{@ingredient_medicament_recipe.errors.inspect}")
      flash[:type] = 'error'
      flash[:notice] = "No se pudo borrar el ingrediente de la receta de medicamentos"
    end

    redirect_to edit_medicament_recipe_path(params[:medicament_recipe_id])
  end
end
