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
    if !client.nil? & client.closed?
      client = nil
    end
    return client
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
      recipe_exist = Recipe.where(code: recipe[:codigo]).first
      product = Product.find_by(code: recipe[:cod_producto])
      if recipe_exist.nil? & !product.nil?
        Recipe.create code: recipe[:codigo],
                      name: recipe[:nombre],
                      version: recipe[:version],
                      product_id: product.id,
                      comment: recipe[:comentario]
      end
      client = connect_sqlserver
      if !client.nil?
        consult = client.execute("select * from dbo.detalle_receta where cod_receta = \"#{recipe[:codigo]}\"")
        result = consult.each(:symbolize_keys => true)
        create_recipe_ingredients(result, recipe[:codigo])
        sql = "update dbo.recetas set procesada = 1 where codigo = \"#{recipe[:codigo]}\""
        result = client.execute(sql)
        result.insert
        client.close
      end
    end
  end

  def create_recipe_ingredients(hash_array, recipe_code)
    #tmp_dir = get_mango_field('tmp_dir')
    recipe = Recipe.where(code: recipe_code).first
    #file = File.open(tmp_dir+"#{recipe_code}.txt",'w')
    #file << hash_array+"\r\n"
    hash_array.each do |ing|
      ingredient = Ingredient.find_by(code: ing[:cod_producto])
      if !recipe.nil? & !ingredient.nil?
        if IngredientRecipe.where(ingredient_id: ingredient.id, recipe_id: recipe.id).first
          #file << "ingredient #{ingredient.name} exits on recipe #{recipe.code} ****\r\n"
          puts "ing existe"
        else
          #file << "create ingredient #{ingredient.name} on recipe #{recipe.code}\r\n"
          IngredientRecipe.create ingredient_id: ingredient.id,
                                  recipe_id: recipe.id,
                                  amount: ing[:cantidad_estandar],
                                  priority: ing[:prioridad]
        end
      end
    end
    #file.close
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
                     prog_batches: order[:batch_prog]
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

end
