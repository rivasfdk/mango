# encoding: UTF-8
include MangoModule

class RecipesController < ApplicationController
  def index
    @recipes = Recipe.search(params)
    @last_imported_recipe = LastImportedRecipe.last
  end

  def show
    @recipe = Recipe.find params[:id], include: {ingredient_recipe: {ingredient: {}}}, order: 'id desc'
    @total = @recipe.get_total()
    @parameter_list_enabled = is_mango_feature_available("recipe_parameters")
    @parameter_list = ParameterList.find_by_recipe(@recipe.code)
  end

  def new
    @products = Product.all
  end

  def edit
    @recipe = Recipe.find params[:id], include: {ingredient_recipe: {ingredient: {}}}, order: 'id desc'
    @total = @recipe.get_total()
    @products = Product.all
    @ingredients = Ingredient.all
    @parameter_list = ParameterList.find_by_recipe(@recipe.code)
    @parameter_list_enabled = is_mango_feature_available("recipe_parameters")
    @parameters_types = ParameterType.all
  end

  def create
    @recipe = Recipe.new params[:recipe]
    if @recipe.save
      flash[:notice] = 'Receta guardada con éxito'
      redirect_to :recipes
    else
      render :new
    end
  end

  def clone
    original_recipe = Recipe.find params[:id]
    @recipe = original_recipe.dup
    @recipe.version = @recipe.version.succ
    @recipe.save
 
    original_recipe.ingredient_recipe.each do |ir|
      new_ir = ir.dup
      new_ir.recipe_id = @recipe.id
      new_ir.save
    end

    original_recipe.in_use = false
    original_recipe.save
    
    @ingredients = Ingredient.all
    @products = Product.all
    render :edit
  end

  def update
    @recipe = Recipe.find params[:id]
    @recipe.update_attributes(params[:recipe])
    if @recipe.save
      flash[:notice] = 'Receta actualizada con éxito'
      redirect_to :recipes
    else
      edit
      render :edit
    end
  end

  def destroy
    @recipe = Recipe.find params[:id]
    @ingredients = Ingredient.find :all
    @recipe.eliminate
    if @recipe.errors.size.zero?
      flash[:notice] = "Receta eliminada con éxito"
    else
      logger.error("Error eliminando receta: #{@recipe.errors.inspect}")
      flash[:type] = 'error'
      if not @recipe.errors[:foreign_key].nil?
        flash[:notice] = 'La receta no se puede eliminar porque tiene registros asociados'
      elsif not @recipe.errors[:unknown].nil?
        flash[:notice] = @recipe.errors[:unknown]
      else
        flash[:notice] = "La receta no se ha podido eliminar"
      end
    end
    redirect_to :recipes
  end
  
  def deactivate
    @recipe = Recipe.find params[:id]
    @recipe.deactivate
    if @recipe.errors.size.zero?
      flash[:notice] = "Receta desactivada con éxito"
    else
      logger.error("Error desactivando receta: #{@recipe.errors.inspect}")
      flash[:type] = 'error'
      flash[:notice] = "La receta no se ha podido desactivar"
    end
    redirect_to :recipes
  end

  def create_parameter_list
    @parameter_list = ParameterList.new
    @recipe = Recipe.find params[:id]
    @parameter_list.recipe_code = @recipe.code
    @parameter_list.save
    redirect_to request.referer + "#parameters"
  end

  def upload
    if params[:recipe]['datafile'].nil?
      flash[:type] = 'error'
      flash[:notice] = "Debe seleccionar un archivo"
      logger.error(flash[:notice])
      redirect_to :action => 'import'
    else
      overwrite = (params[:recipe]['overwrite'] == '1') ? true : false
      name =  params[:recipe]['datafile'].original_filename
      logger.info("Importando el archivo #{name}")
      tmpfile = Tempfile.new "recipe"
      filepath = tmpfile.path()
      tmpfile.write(params[:recipe]['datafile'].read.force_encoding("ISO-8859-1"))
      tmpfile.close()

      @recipe = Recipe.new
      if @recipe.import(filepath, overwrite)
        flash[:notice] = "Receta importada con éxito"
        @last_imported_recipe = LastImportedRecipe.last
        @last_imported_recipe.name = name
        @last_imported_recipe.save
        redirect_to :action => 'index'
      else
        flash[:type] = 'error'
        flash[:notice] = "Error importando receta"
        puts "#{@recipe.errors.inspect}"
        if not @recipe.errors[:upload_file].nil?
          flash[:notice] += ". #{@recipe.errors[:upload_file]}"
        elsif not @recipe.errors[:syntax].nil?
          flash[:notice] = "Error de sintaxis en la línea #{@recipe.errors[:syntax]}"
        elsif not @recipe.errors[:unknown].nil?
          flash[:notice] += ". #{@recipe.errors[:unknown]}"
        end
        logger.error(@recipe.errors.inspect)
        redirect_to :action => 'import'
      end
    end
  end
end
