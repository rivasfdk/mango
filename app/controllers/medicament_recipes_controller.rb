class MedicamentRecipesController < ApplicationController
  def index
    @medicament_recipes = MedicamentRecipe.paginate :page=>params[:page], :per_page=>session[:per_page], :conditions => ['active = ?', true]
  end

  def show
    @medicament_recipe = MedicamentRecipe.find(params[:id], :include=>'ingredient_medicament_recipe', :order=>'id desc')
  end

  def edit
    @medicament_recipe = MedicamentRecipe.find(params[:id], :include=>'ingredient_medicament_recipe', :order=>'id desc')
    @ingredients = Ingredient.find :all
  end

  def create
    @medicament_recipe = MedicamentRecipe.new params[:medicament_recipe]
    if @medicament_recipe.save
      flash[:notice] = 'Receta guardada con éxito'
      redirect_to :medicament_recipes
    else
      render :new
    end
  end

  def update
    @medicament_recipe = MedicamentRecipe.find params[:id]
    @medicament_recipe.update_attributes(params[:medicament_recipe])
    if @medicament_recipe.save
      flash[:notice] = 'Receta de medicamentos actualizada con éxito'
      redirect_to :medicament_recipes
    else
      edit
      render :edit
    end
  end

  def destroy
    @medicament_recipe = MedicamentRecipe.find params[:id]
    @ingredients = Ingredient.find :all
    @medicament_recipe.eliminate
    if @medicament_recipe.errors.size.zero?
      flash[:notice] = "Receta de medicamento eliminada con éxito"
    else
      logger.error("Error eliminando receta: #{@medicament_recipe.errors.inspect}")
      flash[:type] = 'error'
      if not @medicament_recipe.errors[:foreign_key].nil?
        flash[:notice] = 'La receta de medicamentos no se puede eliminar porque tiene registros asociados'
      elsif not @recipe.errors[:unknown].nil?
        flash[:notice] = @recipe.errors[:unknown]
      else
        flash[:notice] = "La receta de medicamentos no se ha podido eliminar"
      end
    end
    redirect_to :medicament_recipes
  end
end
