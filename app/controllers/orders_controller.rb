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
    @order = Order.find params[:id]
    mango_features = get_mango_features()
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
