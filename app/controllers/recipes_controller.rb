# encoding: UTF-8
include MangoModule

class RecipesController < ApplicationController
  def index
    @all_recipes = Recipe.where(active: true)
    @recipes = Recipe.search(params)
    @last_imported_recipe = LastImportedRecipe.last
  end

  def show
    @recipe = Recipe.find params[:id], include: {ingredient_recipe: {ingredient: {}}}, order: 'ingredients.code asc'
    @types = Recipe::TYPES
    @total = @recipe.get_total()
    @parameter_list_enabled = is_mango_feature_available("recipe_parameters")
    if params[:format].nil?
      @parameter_list = ParameterList.find_by_recipe(@recipe.code)
    else
      @parameter_list = ParameterList.includes(:parameters).where(id: params[:format]).first
    end
    @internal_consumption = is_mango_feature_available("internal_consumption")
  end

  def new
    @products = Product.all
    @types = Recipe::TYPES
    @internal_consumption = is_mango_feature_available("internal_consumption")
  end

  def edit
    @recipe = Recipe.find params[:id], include: {ingredient_recipe: {ingredient: {}}}, order: 'ingredients.code desc'
    @total = @recipe.get_total()
    @products = Product.all
    @ingredients = Ingredient.actives.all
    @types = Recipe::TYPES
    @parameter_list = ParameterList.find_by_recipe(@recipe.code)
    @parameter_list_enabled = is_mango_feature_available("recipe_parameters")
    @parameters_types = ParameterType.all
    @internal_consumption = is_mango_feature_available("internal_consumption")
    @recipe_approval = is_mango_feature_available("recipe_approval")
    @granted_approval = User.find(session[:user_id]).has_global_permission?('recipes', 'delete')
  end

  def create
    @recipe = Recipe.new params[:recipe]
    if @recipe.save
      Log.create type_id: 3, user_id: session[:user_id], 
                 action: "Receta CREADA: #{@recipe.name} codigo: #{@recipe.code} versión: #{@recipe.version}"
      flash[:notice] = 'Receta guardada con éxito'
      redirect_to :recipes
    else
      new
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

    if is_mango_feature_available("recipe_approval")
      @recipe.in_use = false
      @recipe.save
    else
      original_recipe.in_use = false
      original_recipe.save
    end

    Log.create type_id: 3, user_id: session[:user_id], 
                 action: "Receta CLONADA: #{@recipe.name} codigo: #{@recipe.code} versión: #{@recipe.version} "+
                 "versión anterior: #{original_recipe.version}"
    
    @ingredients = Ingredient.actives.all
    @products = Product.all
    @types = Recipe::TYPES
    @recipe_approval = is_mango_feature_available("recipe_approval")
    @granted_approval = User.find(session[:user_id]).has_global_permission?('recipes', 'delete')
    render :edit
  end

  def update
    @recipe = Recipe.find params[:id]
    in_use_old = @recipe.in_use
    active_old = @recipe.active
    @recipe.update_attributes(params[:recipe])
    in_use = @recipe.in_use
    active = @recipe.active
    if @recipe.save
      if (in_use != in_use_old) && in_use
        Log.create type_id: 3, user_id: session[:user_id], 
                   action: "Receta HABILITADA para usar: #{@recipe.name} codigo: #{@recipe.code} versión: #{@recipe.version}"
      end
      if (active != active_old) && !active
        Log.create type_id: 3, user_id: session[:user_id], 
                   action: "Receta DESACTIVADA del sistema: #{@recipe.name} codigo: #{@recipe.code} versión: #{@recipe.version}"
      end
      Log.create type_id: 3, user_id: session[:user_id], 
                 action: "Receta EDITADA: #{@recipe.name} codigo: #{@recipe.code} versión: #{@recipe.version} "
      flash[:notice] = 'Receta actualizada con éxito'
      redirect_to :recipes
    else
      edit
      render :edit
    end
  end

  def destroy
    @recipe = Recipe.find params[:id]
    @ingredients = Ingredient.actives
    @recipe.eliminate
    if @recipe.errors.empty?
      Log.create type_id: 3, user_id: session[:user_id], 
                 action: "Receta ELIMINADA: #{@recipe.name} codigo: #{@recipe.code} versión: #{@recipe.version}"
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
    if @recipe.errors.empty?
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

  def import
    mango_features = get_mango_features()
    if mango_features.include?("import_recipes")
      company = get_mango_field('company')
      case company
      when 5 #************************Tecavi**************************
        client = connect_sqlserver

        consult = client.execute("select * from dbo.Formula where nForEstado < 2")
        recipes_sql = consult.each(:symbolize_keys => true)

        products_sql = []
        recipes_sql.each do |recipe|
          consult = client.execute("select * from dbo.Producto where Producto_Id = #{recipe[:nForAlimento_Id]} and nProEstado < 2")
          products_sql << consult.each(:symbolize_keys => true)[0]
        end

        products = []
        products_sql.each do |product|
          hash = {}
          unless product.nil?
            hash[:code] = product[:Producto_Id]
            hash[:name] = product[:sProNombre]
            products << hash
          end
        end

        saved_products = products(products)

        saved_products.each do |code|
          sql = "update dbo.Producto set nProEstado = 2 where Producto_Id = #{code}"
          result = client.execute(sql)
          result.insert
        end

        all_products = Product.all

        product_lots = []
        all_products.each do |product|
          consult = client.execute("select * from dbo.Producto_Lote where Producto_Id = #{product.code}")
          lots_sql = consult.each(:symbolize_keys => true)
          unless product.nil?
            unless lots_sql.empty?
              lots_sql.each do |lot|
                hash = {}
                hash[:product_code] = lot[:Producto_Id]
                hash[:lot_code] = lot[:sPLoNumeroLote]
                product_lots << hash
              end
            end
          end
        end

        saved_product_lots = product_lots(product_lots)

        saved_product_lots.each do |lot|
          sql = "update dbo.Producto_Lote set nPLoEstado = 2 where sPLoNumeroLote = \"#{lot[0]}\" and Producto_Id = #{lot[1]}"
          result = client.execute(sql)
          result.insert
        end

        ingredients = []
        recipes_sql.each do |recipe|
          consult = client.execute("select * from dbo.Formula_Detalle where Formula_Id = #{recipe[:Formula_Id]}")
          ingredients_sql = consult.each(:symbolize_keys => true)
          ingredients_sql.each do |ingredient|
            consult = client.execute("select * from dbo.Producto where Producto_Id = #{ingredient[:Producto_Id]} and nProEstado < 2")
            product = consult.each(:symbolize_keys => true)[0]
            unless product.nil?
              hash = {}
              hash[:code] = ingredient[:Producto_Id]
              hash[:name] = product[:sProNombre]
              ingredients << hash
            end
          end
        end
        ingredients = ingredients & ingredients

        saved_ingredients = ingredients(ingredients)

        saved_ingredients.each do |code|
          sql = "update dbo.Producto set nProEstado = 2 where Producto_Id = #{code}"
          result = client.execute(sql)
          result.insert
        end

        all_ingredients = Ingredient.all

        lots = []
        all_ingredients.each do |ingredient|
          consult = client.execute("select * from dbo.Producto_Lote where Producto_Id = #{ingredient.code}")
          lots_sql = consult.each(:symbolize_keys => true)
          unless ingredient.nil?
            unless lots_sql.empty?
              lots_sql.each do |lot|
                hash = {}
                hash[:ingredient_code] = lot[:Producto_Id]
                hash[:lot_code] = lot[:sPLoNumeroLote]
                lots << hash
              end
            end
          end
        end

        saved_lots = lots(lots)

        saved_lots.each do |lot|
          sql = "update dbo.Producto_Lote set nPLoEstado = 2 where sPLoNumeroLote = \"#{lot[0]}\" and Producto_Id = #{lot[1]}"
          result = client.execute(sql)
          result.insert
        end
  
        recipes = []
        recipes_sql.each do |recipe|
          consult = client.execute("select * from dbo.Producto where Producto_Id = #{recipe[:nForAlimento_Id]}")
          product = consult.each(:symbolize_keys => true)[0]
          hash = {}
          hash[:code] = recipe[:sForNumero]
          hash[:name] = product[:sProNombre]
          hash[:version] = 1
          hash[:product_code] = product[:Producto_Id]
          recipes << hash
        end

        saved_recipes = recipes(recipes)

        saved_recipes.each do |recipe|
          sql = "update dbo.Formula set nForEstado = 2 where sForNumero = \"#{recipe[0]}\""
          result = client.execute(sql)
          result.insert
        end

        ingredients_recipes = []
        recipes_sql.each do |recipe|
          consult = client.execute("select * from dbo.Formula_Detalle where Formula_Id = #{recipe[:Formula_Id]}")
          ingredients_sql = consult.each(:symbolize_keys => true)
          ingredients_sql.each do |ingredient|
            consult = client.execute("select * from dbo.Producto where Producto_Id = #{ingredient[:Producto_Id]}")
            product = consult.each(:symbolize_keys => true)[0]
            hash = {}
            hash[:recipe_code] = recipe[:sForNumero]
            hash[:version] = 1
            hash[:ingredient_code] = ingredient[:Producto_Id]
            hash[:amount] = ingredient[:nFDeCantidad]
            ingredients_recipes << hash
          end
        end

        ingredients_recipes(ingredients_recipes)

      else
      end
      if saved_products.length > 0 or saved_product_lots.length > 0 or saved_ingredients.length > 0 or saved_lots.length > 0 or saved_recipes.length > 0
        flash[:notice] = "Se importaron  #{saved_products.length} PT, #{saved_product_lots.length} LPT, #{saved_ingredients.length} MP,"+
                         " #{saved_lots.length} LMP, #{saved_recipes.length} Recetas con éxito"
      else
        flash[:notice] = "No se encontraro datos para importar"
      end
      redirect_to :action => 'index'
    end 
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

  def print_recipe
    @recipe = Recipe.find params[:id]
    @data = EasyModel.recipe_details(@recipe.id)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'recipes/recipe_details', target: "_blank"
      send_data rendered, filename: "detalle_orden_rectea.pdf", type: "application/pdf", disposition: 'inline'
    end
  end
    
end
