# encoding: UTF-8

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  before_filter :store_location, :check_authentication, :check_permissions
  skip_before_filter :verify_authenticity_token
 
  helper :flash
  helper :modal
  include ModalHelper::Modal

  # Pagination config
  PaginationHelper::DEFAULT_OPTIONS[:prev_title] = ''
  PaginationHelper::DEFAULT_OPTIONS[:next_title] = ''
  PaginationHelper::DEFAULT_OPTIONS[:first_title] = ''
  PaginationHelper::DEFAULT_OPTIONS[:last_title] = ''
  PaginationHelper::DEFAULT_OPTIONS[:prev_tooltip] = 'Pág. anterior'
  PaginationHelper::DEFAULT_OPTIONS[:next_tooltip] = 'Pág. siguiente'
  PaginationHelper::DEFAULT_OPTIONS[:first_tooltip] = 'Primera pág.'
  PaginationHelper::DEFAULT_OPTIONS[:last_tooltip] = 'Última pág.'

  def check_authentication
    unless session[:user_id]
      respond_to do |format|
        format.html do
          session[:request] = action_name
          redirect_to sessions_path
        end
        format.json { head :unauthorized }
        format.xml { head :unauthorized }
      end
    end
  end

  def check_permissions
    return true if (controller_name == 'sessions')
    granted = User.find(session[:user_id]).has_global_permission?(controller_name, action_name)
    return true if granted
    flash[:notice] = "No tiene permiso para acceder a ese recurso"
    flash[:type] = 'error'
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to :action=>'show', :controller=>'sessions')
    return false
  end

  def store_location
    return unless request.get?

    path = request.fullpath
    if (path != '/sessions' && !request.xhr?)
      session[:previous_url] = path
    end
  end

  def connect_sqlserver
    sqlserver = get_mango_field('sql_server')
    begin
      client = TinyTds::Client.new username: sqlserver["username"],
                                   password: sqlserver["password"],
                                   dataserver: sqlserver["dataserver"],
                                   database: sqlserver["database"]
    rescue
      client = nil
    end
    if client.nil? 
      client = nil
    else
      if client.closed?
        client = nil
      end
    end
    return client
  end

  def import_orders(orders, ingredients)

    order_count = 0
    message = ""

    orders.each do |order|
      if Product.where(code: order[:cod_producto]).empty?
        Product.create code: order[:cod_producto],
                      name: order[:nom_producto]
      end
      product = Product.find_by(code: order[:cod_producto])
      if ProductLot.where(code: order[:cod_producto]).empty?
        ProductLot.create code: order[:cod_producto],
                          product_id: product.id
      end

      ingredients.each do |ing|
        if Ingredient.where(code: ing[:cod_material]).empty?
          Ingredient.create code: ing[:cod_material],
                            name: ing[:nombre_material],
                            minimum_stock: 0.0
        end
        ingredient = Ingredient.find_by(code: ing[:cod_material])
        if Lot.where(code: ing[:cod_material]).empty?
          Lot.create code: ing[:cod_material],
                    ingredient_id: ingredient.id,
                    density: 1000
        end
      end


      product = Product.find_by(code: order[:cod_producto])
      if Recipe.where(code: order[:cod_receta], version: order[:ver_receta]).empty?
        Recipe.create code: order[:cod_receta],
                      name: order[:nom_receta],
                      version: order[:ver_receta],
                      product_id: product.id
      
        recipe = Recipe.find_by(code: order[:cod_receta],version: order[:ver_receta])

        ingredients.each do |ing|
          if ing[:cod_orden] == order[:cod_orden]
            ingredient = Ingredient.find_by(code: ing[:cod_material])
            IngredientRecipe.create ingredient_id: ingredient.id,
                                    recipe_id: recipe.id,
                                    amount: ing[:cant_material]
            client = connect_sqlserver
            if !client.nil?
              date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
              sql = "update dbo.ordenpd set estado = \"procesada\" where cod_orden = #{ing[:cod_orden]} and cod_material = \"#{ing[:cod_material]}\""
              result = client.execute(sql)
              result.insert
              sql = "update dbo.ordenpd set fecha_cierra = #{date} where cod_orden = #{ing[:cod_orden]} and cod_material = \"#{ing[:cod_material]}\""
              result = client.execute(sql)
              result.insert
              client.close
            end
          end
        end
      end
      
  
      if Client.where(code: order[:cod_cliente]).empty?
        Client.create code: order[:cod_cliente],
                      name: order[:nom_cliente],
                      ci_rif: order[:rif_cliente],
                      address: order[:dir_cliente],
                      tel1: order[:tel_cliente]
      end

      recipe = Recipe.find_by(code: order[:cod_receta],version: order[:ver_receta])
      client = Client.find_by(code: order[:cod_cliente])
      product_lot = ProductLot.find_by(code: order[:cod_producto])
      if product_lot.nil?
        message = "Error en el archivo a importar"
      else
        length = order[:cod_orden].length
        if length > 10
          start = length -10
          order[:cod_orden] = order[:cod_orden][start,length]
        end
        if Order.where(code: order[:cod_orden]).empty?
          cant_batches = order[:cant_batch].to_i
          Order.create code: order[:cod_orden],
                      recipe_id: recipe.id,
                      client_id: client.id,
                      user_id: 1,
                      product_lot_id: product_lot.id,
                      prog_batches: cant_batches,
                      processed_in_baan: true
          if !(Order.find_by(code: order[:cod_orden])).nil?
            order_count += 1
            #client = connect_sqlserver
            #if !client.nil?
            #  sql = "update dbo.ordenp set estado = \"procesada\" where cod_orden = #{order[:cod_orden]}"
            #  result = client.execute(sql)
            #  result.insert
            #  client.close
            #end
          end
        end
      end
    end
  
    puts message

    return order_count
    
  end

  def close_order(order)

  end

  def create_products(hash_array)
    hash_array.each do |ing|
      content = ing[:tipo].downcase == 'mp' ? true : false
      if content
        if Ingredient.where(code: ing[:codigo]).empty?
          Ingredient.create code: ing[:codigo],
                            name: ing[:nombre]
        end
        ingredient = Ingredient.find_by(code: ing[:codigo])
        if Lot.where(code: ing[:codigo]).empty? & !ingredient.nil?
          Lot.create code: ing[:codigo],
                     ingredient_id: ingredient.id,
                     density: 1000
        end
      else
        if Product.where(code: ing[:codigo]).empty?
          Product.create code: ing[:codigo],
                         name: ing[:nombre]
        end
        product = Product.find_by(code: ing[:codigo])
        if ProductLot.where(code: ing[:codigo]).empty? & !product.nil?
          ProductLot.create code: ing[:codigo],
                            product_id: product.id
        end
      end
      client = connect_sqlserver
      if !client.nil?
        sql = "update dbo.productos set procesada = 1 where codigo = \"#{ing[:codigo]}\""
        result = client.execute(sql)
        result.insert
        client.close
      end
    end
  end

  def create_clients(hash_array)
    hash_array.each do |client|
      if Client.where(code: client[:codigo]).empty?
        Client.create code: client[:codigo],
                      name: client[:nombre],
                      ci_rif: client[:rif],
                      address: client[:direccion],
                      tel1: client[:telefono1]
        clientsql = connect_sqlserver
        if !clientsql.nil?
          sql = "update dbo.clientes set procesada = 1 where codigo = \"#{client[:codigo]}\""
          result = clientsql.execute(sql)
          result.insert
          clientsql.close
        end
      end
    end
  end

  def create_recipes(hash_array)
    hash_array.each do |recipe|
      recipe_exist = Recipe.where(code: recipe[:codigo], active: true).first
      product = Product.find_by(code: recipe[:cod_producto])
      if recipe_exist.nil? & !product.nil?
        Recipe.create code: recipe[:codigo],
                      name: recipe[:nombre],
                      version: recipe[:version],
                      active: true,
                      product_id: product.id,
                      comment: recipe[:comentario]
      end
      client = connect_sqlserver
      if !client.nil?
        consult = client.execute("select * from dbo.detalle_receta where cod_receta = \"#{recipe[:codigo]}\"")
        result = consult.each(:symbolize_keys => true)
        create_recipe_ingredients(result, recipe[:codigo])
        client.close
      end
    end
  end

  def create_recipe_ingredients(hash_array, recipe_code)
    tmp_dir = get_mango_field('tmp_dir')
    file = File.open(tmp_dir+"#{recipe_code}.txt",'w')
    file << "#{hash_array}\r\n"
    recip = Recipe.find_by(code: recipe_code, active: true)
    if !recip.nil?
      hash_array.each do |ing|

        @recipe = Recipe.find(recip.id, :include=>'ingredient_recipe')
        ingredient = Ingredient.where(code: ing[:cod_producto]).first

        if !@recipe.nil? & !ingredient.nil?
          if IngredientRecipe.where(ingredient_id: ingredient.id, recipe_id: @recipe.id).first.nil?
            file << "create ingredient #{ingredient.name} on recipe #{@recipe.code}\r\n"
            ingredient_recipe = IngredientRecipe.new
            ingredient_recipe.ingredient = ingredient
            ingredient_recipe.recipe = @recipe
            ingredient_recipe.priority = ing[:prioridad]
            ingredient_recipe.amount = ing[:cantidad_estandar]
            ingredient_recipe.percentage = 0.0

            if ingredient_recipe.valid?
              ingredient_recipe.save
            end
          end
        end

      end
    else
      file << "receta no existe"
    end
    file.close
    client = connect_sqlserver
    if !client.nil?
      sql = "update dbo.recetas set procesada = 1 where codigo = \"#{recipe_code}\""
      result = client.execute(sql)
      result.insert
      client.close
    end
  end

  def create_orders(hash_array)
    count = 0
    hash_array.each do |order|
      recipe = Recipe.where(code: order[:cod_receta]).last
      client = Client.find_by(code: order[:cod_cliente])
      product_lot = ProductLot.find_by(code: order[:cod_lote])
      if Order.where(code: order[:codigo]).empty? & !recipe.nil? & !client.nil? & !product_lot.nil?
        Order.create code: order[:codigo],
                     recipe_id: recipe.id,
                     client_id: client.id,
                     user_id: 1,
                     product_lot_id: product_lot.id,
                     prog_batches: order[:batch_prog],
                     processed_in_baan: true
        count += 1
        client = connect_sqlserver
        if !client.nil?
          sql = "update dbo.orden_produccion set procesada = 1 where codigo = \"#{order[:codigo]}\""
          result = client.execute(sql)
          result.insert
          client.close
        end
      end
    end
    return count
  end

  def products(products)
    products.each do |product|
      if Product.where(code: product[:code]).empty?
        new_product = Product.new
        new_product.code = product[:code]
        new_product.name = product[:name]
        new_product.save
      end
    end
  end

  def product_lots(product_lots)
    product_lots.each do |product_lot|
      product = Product.where(code: product_lot[:product_code]).first
      unless product.nil?
        if ProductLot.where(code: product_lot[:lot_code]).empty?
          new_product_lot = ProductLot.new
          new_product_lot.code = product_lot[:lot_code]
          new_product_lot.product_id = product.id
          new_product_lot.save
        end
      end
    end
  end

  def ingredients(ingredients)
    ingredients.each do |ingredient|
      if Ingredient.where(code: ingredient[:code]).empty?
        new_ingredient = Ingredient.new
        new_ingredient.code = ingredient[:code]
        new_ingredient.name = ingredient[:name]
        new_ingredient.save
      end
    end
  end

  def lots(lots)
    lots.each do |lot|
      ingredient = Ingredient.where(code: lot[:ingredient_code]).first
      unless ingredient.nil?
        if Lot.where(code: lot[:lot_code]).empty?
          new_lot = Lot.new
          new_lot.code = lot[:lot_code]
          new_lot.ingredient_id = ingredient.id
          new_lot.density = 1000
          new_lot.save
        end
      end
    end
  end

  def recipes(recipes)
    count = 0
    recipes.each do |recipe|
      product = Product.where(code: recipe[:product_code]).first
      unless product.nil?
        if Recipe.where(code: recipe[:code], version: recipe[:version]).empty?
          new_recipe = Recipe.new
          new_recipe.code = recipe[:code]
          new_recipe.name = recipe[:name]
          new_recipe.version = recipe[:version]
          new_recipe.product_id = product.id
          new_recipe.save
          count += 1
        end
      end
    end
    return count
  end

  def ingredients_recipes(ingredients_recipes)
    ingredients_recipes.each do |irecipe|
      ingredient = Ingredient.where(code: irecipe[:ingredient_code]).first
      recipe = Recipe.where(code: irecipe[:recipe_code], version: irecipe[:version]).first
      unless ingredient.nil? or recipe.nil?
        if IngredientRecipe.where(ingredient_id: ingredient.id, recipe_id: recipe.id).empty?
          ingredient_recipe = IngredientRecipe.new
          ingredient_recipe.ingredient = ingredient
          ingredient_recipe.recipe = recipe
          ingredient_recipe.amount = irecipe[:amount]
          ingredient_recipe.save
        end
      end
    end
  end

end
