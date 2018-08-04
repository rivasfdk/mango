# encoding: UTF-8

include MangoModule

class OrdersController < ApplicationController
  def index
    @orders = Order.search(params)
    @clients = Client.get_all()
    @recipes = Recipe.lastests_by_code()
    @states = Order::STATES
  end

  def show
    order = Order.find params[:id]
    @data = EasyModel.order_details(order.code)
    @parameter_list = ParameterList.includes(:parameters).where(id: order.parameter_list_id).first
    mango_features = get_mango_features()
    @real_production_enabled = mango_features.include?("real_production")
  end

  def new
    @recipes = Recipe.where({active: true, in_use: true}).order('name ASC')
    @medicament_recipes = MedicamentRecipe.where(active: true).order('name ASC')
    @clients = Client.get_all().select {|c| not c.factory}
    @product_lots = []
    @users = User.order('name ASC')
    @order = Order.new if @order.nil?
    @order_code = 'Autogenerado'
    @user = User.find session[:user_id]
    @can_edit_real_production = @user.has_global_permission?('orders', 'edit_real_production')
    @order.user_id = @user.id unless @user.admin?
    @factory_checked = false
    mango_features = get_mango_features()
    @real_production_enabled = mango_features.include?("real_production")
    @factories_enabled = mango_features.include?("factories")
    @medicament_recipes_enabled = mango_features.include?("medicament_recipes")
    @auto_product_lot_enabled = mango_features.include?("auto_order_product_lot")
  end

  def edit
    @order = Order.find(params[:id])
    new
    if @order.client.factory
      @clients = Client.where(factory: true)
      @factory_checked = true
    end
    @product_lots = ProductLot.includes(:product)
                              .where(active: true)
                              .where(product_id: @order.recipe.product_id)
    @order_code = @order.code
    @user = User.find session[:user_id]
  end

  def create
    @order = Order.new params[:order]
    @order.parameter_list = ParameterList.find_by_recipe(@order.recipe.code) unless @order.recipe_id.nil?
    if @order.save
      flash[:notice] = 'Orden de producción guardada con éxito'
      redirect_to :orders
    else
      new
      render :new
    end
  end

  def update
    @order = Order.find params[:id]
    @order.update_attributes(params[:order])
    if @order.save
      flash[:notice] = 'Orden de producción actualizada con éxito'
      redirect_to :orders
    else
      new
      render :edit
    end
  end

  def destroy
    @order = Order.find params[:id]
    @order.eliminate
    if @order.errors.empty?
      flash[:notice] = 'Orden de producción eliminada con éxito'
    else
      logger.error("Error eliminando orden: #{@order.errors.inspect}")
      flash[:type] = 'error'
      if not @order.errors[:foreign_key].nil?
        flash[:notice] = 'La orden no se puede eliminar porque tiene registros asociados'
      elsif not @order.errors[:unknown].nil?
        flash[:notice] = @order.errors[:unknown]
      else
        flash[:notice] = "La orden no se ha podido eliminar"
      end
    end
    redirect_to :orders
  end

  def repair
    @order = Order.find params[:id]
    @data = EasyModel.order_details(@order.code)
    session[:return_to] = request.referer.nil? ? :lots : request.referer
  end

  def do_repair
    n_batch = Integer(params[:n_batch]) rescue 0
    @order = Order.find params[:id]

    if n_batch.between?(1, @order.prog_batches)
      if @order.repair(session[:user_id], params)

        mango_features = get_mango_features()
        if mango_features.include?("sap_sqlserver") and @order.processed_in_baan
          sql_server_type = get_mango_field('sql_server_type')
          case sql_server_type
          when 2 #**************************Agroebenezer***************************
            data = EasyModel.order_details(@order.code)
            results = data['results']
            date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
            client = connect_sqlserver
            if !client.nil?
              sql = "update dbo.ordenp set cant_batchreal = #{@order.batch.count} where cod_orden = 10#{@order.code}"
              puts sql
              result = client.execute(sql)
              result.insert
              sql = "update dbo.ordenp set fecha_cierra = #{date} where cod_orden = 10#{@order.code}"
              result = client.execute(sql)
              result.insert
              results.each do |result|
                sql = "insert into dbo.sofos "+
                      "values (10#{@order.code}, \"#{result["code"]}\", #{result["real_kg"]}, #{date})"
                puts sql
                result = client.execute(sql)
                result.insert
              end
              client.close
            end
          when 3 #*************************Alceca*************************
            data = EasyModel.order_details(@order.code)
            results = data['results']
            date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
            client = connect_sqlserver
            if !client.nil?
              sql = "update dbo.ordenp set cant_batchreal = #{@order.batch.count}, fecha_cierra = #{date} where cod_orden = #{@order.code}"
              puts sql
              result = client.execute(sql)
              result.insert
            end
            results.each do |result|
              if !client.nil?
                sql = "insert into dbo.ordenpcons "+
                      "values (#{@order.code}, \"#{result["code"]}\", #{result["real_kg"]},NULL, #{date}, NULL)"
                puts sql
                result = client.execute(sql)
                result.insert
              end
            end
            client.close
          else
          end
        end

        flash[:notice] = "Orden reparada exitosamente"
        redirect_to session[:return_to]
      else
        flash[:type] = 'error'
        flash[:notice] = "Error al reparar la orden"
        redirect_to session[:return_to]
      end
    else
      flash[:type] = 'error'
      flash[:notice] = "El numero de batches es inválido"
      redirect_to session[:return_to]
    end
  end

  def notify
    @order = Order.find params[:id]
    redirect_to :orders unless (@order.completed && !@order.notified)
    @data = EasyModel.order_details(@order.code)
  end

  def do_notify
    warning = ""
    @order = Order.find params[:id]

    mango_features = get_mango_features()
    if mango_features.include?("sap_sqlserver") and @order.processed_in_baan
      if @order.processed_in_baan
        sql_server_type = get_mango_field('sql_server_type')
        case sql_server_type
        when 1 #************************El Tunal**********************
          date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
          for i in 1..@order.prog_batches
            batch = EasyModel.batch_details(@order.code, i)
            batch["results"].each do |ing|
              client = connect_sqlserver
              if !client.nil?
                sql = "insert into dbo.batch "+
                      "values (#{@order.code}, #{i}, #{ing["real_kg"]}, #{date}, "+
                      "\"#{ing["code"]}\", \"#{@order.product_lot.code}\", #{ing["std_kg"]})"
                puts sql
                result = client.execute(sql)
                result.insert
                client.close
              end
            end
          end
          client = connect_sqlserver
          if !client.nil?
            sql = "update dbo.orden_produccion set cerrada = 1 where codigo = #{@order.code}"
            puts sql
            result = client.execute(sql)
            result.insert
            client.close
          end
        when 2 #*************************AgroEbenezer*************************
          data = EasyModel.order_details(@order.code)
          results = data['results']
          results.each do |result|
            client = connect_sqlserver
            date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
            if !client.nil?
              sql = "insert into dbo.sofos "+
                    "values (10#{@order.code}, \"#{result["code"]}\", #{result["real_kg"]}, #{date})"
              puts sql
              result = client.execute(sql)
              result.insert
              client.close
            end
          end
        else

        end

      end

    end


    if mango_features.include?("sap_production_order")
      warning = @order.nofify_sap
    end
    if warning.empty?
      if (@order.completed && !@order.notified)
        @order.generate_transactions(session[:user_id])
        @order.update_column(:notified, true)
        flash[:notice] = "Orden notificada exitosamente"
      end
    else
      flash[:type] = "error"
      flash[:notice] = warning
    end
    redirect_to :orders
  end

  def generate_transactions
    @order = Order.find params[:id]
    @order.generate_transactions(session[:user_id])
    redirect_to :orders
  end

  def generate_consumption
    errors = Order.generate_consumption(params[:consumption], session[:user_id])
    render xml: errors
  end

  def generate_not_weighed_consumptions
    errors = Order.generate_not_weighed_consumptions(params[:order_batch], session[:user_id])
    render xml: {success: errors.empty?}
  end

  def consumption_exists
    render xml: {exists: Order.consumption_exists(params)}
  end

  def close
    @order = Order.where(code: params[:order_code]).first
    render xml: {closed: @order.close(session[:user_id])}

    mango_features = get_mango_features()
    if mango_features.include?("sap_sqlserver") and @order.processed_in_baan
      sql_server_type = get_mango_field('sql_server_type')
      case sql_server_type
      when 2
        @order = Order.where(code: params[:order_code]).first
        client = connect_sqlserver
        date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
        if !client.nil?
          sql = "update dbo.ordenp set cant_batchreal = #{@order.real_batches} where cod_orden = 10#{@order.code}"
          puts sql
          result = client.execute(sql)
          result.insert
          sql = "update dbo.ordenp set fecha_cierra = #{date} where cod_orden = 10#{@order.code}"
          result = client.execute(sql)
          result.insert
          client.close
        end
      when 3 #*************************Alceca*************************
        data = EasyModel.order_details(@order.code)
        results = data['results']
        date = Time.now.strftime "'%Y-%m-%d %H:%M:%S'"
        client = connect_sqlserver
        if !client.nil?
          sql = "update dbo.ordenp set cant_batchreal = #{@order.batch.count}, fecha_cierra = #{date} where cod_orden = #{@order.code}"
          puts sql
          result = client.execute(sql)
          result.insert
        end
        results.each do |result|
          if !client.nil?
            sql = "insert into dbo.ordenpcons "+
                  "values (#{@order.code}, \"#{result["code"]}\", #{result["real_kg"]},NULL, #{date}, NULL)"
            puts sql
            result = client.execute(sql)
            result.insert
          end
        end
        client.close
      else
      end
    end

  end

  def stop
    @order = Order.where(code: params[:order][:order_code]).first
    render xml: {stop: @order.stop(params[:order][:batch_prog])}
  end

  def create_order_stat
    render xml: Order.create_order_stat(params[:order_stat])
  end

  def update_order_area
    render xml: Order.update_order_area(params[:order_area])  
  end

  def print
    @order = Order.find params[:id]
    @data = EasyModel.order_details(@order.code)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/order_details', target: "_blank"
      send_data rendered, filename: "detalle_orden_produccion.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def open
    render xml: Order.get_open, root: 'orders'
  end

  def validate
    order = Order.where(code: params[:order_code]).first
    render xml: order.validate, root: 'order_validation'
  end

  def import

    mango_features = get_mango_features()
    if mango_features.include?("sap_sqlserver")
      sql_server_type = get_mango_field('sql_server_type')
      count = 0
      client = connect_sqlserver
      case sql_server_type
      when 1 #************************El Tunal**********************
        if !client.nil?
          consult = client.execute("select * from dbo.productos  where procesada = 0")
          products = consult.each(:symbolize_keys => true)
          create_products(products)

          consult = client.execute("select * from dbo.clientes  where procesada = 0")
          clients = consult.each(:symbolize_keys => true)
          create_clients(clients)

          consult = client.execute("select * from dbo.recetas where procesada = 0")
          recipes = consult.each(:symbolize_keys => true)
          create_recipes(recipes)

          consult = client.execute("select * from dbo.orden_produccion where procesada = 0")
          orders = consult.each(:symbolize_keys => true)
          count = create_orders(orders)
          client.close

          if count > 0
            flash[:notice] = "Se importaron #{count} ordenes con exito"
          else
            flash[:type] = 'warn'
            flash[:notice] = 'No se encontraron ordenes para importar'
          end

        else
          flash[:type] = 'error'
          flash[:notice] = 'No se pudo conectar con la base de datos'
        end
      when 2 #*****************************AgroEbenezer***************************
        if !client.nil?
          consult = client.execute("select * from dbo.ordenp") #where estado = null
          orders = consult.each(:symbolize_keys => true)
          consult = client.execute("select * from dbo.ordenpd")
          ingrecipes = consult.each(:symbolize_keys => true)
          count = import_orders(orders, ingrecipes)

          if count > 0
            client = connect_sqlserver
            orders.each do |order| 
              if !client.nil?
                sql = "update dbo.ordenp set estado = \"procesada\" where cod_orden = #{order[:cod_orden]}"
                result = client.execute(sql)
                result.insert
              end
            end
            client.close
            flash[:notice] = "Se importaron #{count} ordenes con exito"
          else
            flash[:type] = 'warn'
            flash[:notice] = 'No se encontraron ordenes para importar'
          end

        else
          flash[:type] = 'error'
          flash[:notice] = 'No se pudo conectar con la base de datos'
        end
      when 3 #***********************Alceca*************************************
        if !client.nil?
          plant = get_mango_field('application')
          if plant["name"].include?("NORTE")
            consult = client.execute("select * from dbo.ordenp  where estado = null and cod_cliente = 0001")
            orders = consult.each(:symbolize_keys => true)
          elsif plant["name"].include?("SUR")
            consult = client.execute("select * from dbo.ordenp  where estado = null and cod_cliente = 0002")
            orders = consult.each(:symbolize_keys => true)
          else
            orders = []
          end
          consult = client.execute("select * from dbo.ordenpd  where estado = null")
          ingrecipes = consult.each(:symbolize_keys => true)
          count = import_orders(orders, ingrecipes)

          if count > 0
            client = connect_sqlserver
            orders.each do |order| 
              if !client.nil?
                sql = "update dbo.ordenp set estado = \"procesada\" where cod_orden = #{order[:cod_orden]}"
                result = client.execute(sql)
                result.insert
              end
            end
            client.close
            flash[:notice] = "Se importaron #{count} ordenes con exito"
          else
            flash[:type] = 'warn'
            flash[:notice] = 'No se encontraron ordenes para importar'
          end

        else
          flash[:type] = 'error'
          flash[:notice] = 'No se pudo conectar con la base de datos'
        end

      else
      end
    end
    
    sharepath = get_mango_field('share_path')
    mango_features = get_mango_features()
    if mango_features.include?("sap_production_order")
      files = []
      begin
        files = Dir.entries(sharepath)
      rescue
        puts "++++++++++++++++++++"
        puts "+++ error de red +++"
        puts "++++++++++++++++++++"
      end
      if files.any?
        orders = Order.import(files)
        if orders > 0
          flash[:notice] = "Se importaron #{orders} ordenes con exito"
        else
          flash[:type] = 'warn'
          flash[:notice] = 'No se encontraron ordenes para importar'
        end
      end
    end
    redirect_to action: 'index'
  end

end
