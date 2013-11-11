# encoding: UTF-8

class OrdersController < ApplicationController
  def index
    @orders = Order.search(params)
    @clients = Client.all
    @recipes = Recipe.all(group: :code)
  end

  def new
    @recipes = Recipe.where({active: true, in_use: true}).order('name ASC')
    @medicament_recipes = MedicamentRecipe.where(active: true).order('name ASC')
    @clients = Client.order('name ASC')
    @users = User.order('name ASC')
    @product_lots = ProductLot.order('code ASC')
    @order = Order.new if @order.nil?
    @order_code = 'Autogenerado'
    @user = User.find session[:user_id]
    @can_edit_real_production = @user.has_global_permission?('orders', 'edit_real_production')
    unless @user.admin?
      @order.user_id = @user.id
    end
  end

  def edit
    @order = Order.find(params[:id])
    new
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
    if @order.errors.size.zero?
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
  end

  def do_repair
    n_batch = Integer(params[:n_batch]) rescue 0
    @order = Order.find params[:id]

    if @order.recipe.validate
      if n_batch.between?(1, @order.prog_batches)
        if @order.repair(session[:user_id], n_batch)
          flash[:notice] = "Orden reparada exitosamente"
          redirect_to :orders
        else
          flash[:type] = 'error'
          flash[:notice] = "Faltan lotes necesarios para generar las transacciones"
          redirect_to :orders
        end
      else
        flash[:type] = 'error'
        flash[:notice] = "El numero de batches es inválido"
        redirect_to :orders
      end
    else
      flash[:type] = 'error'
      flash[:notice] = "Algunos ingredientes de la receta no se encuentran en las tolvas"
      redirect_to :orders
    end
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

  def consumption_exists
    render xml: {exists: Order.consumption_exists(params)}
  end

  def close
    @order = Order.find_by_code params[:order_code]
    render xml: {closed: @order.close(session[:user_id])}
  end

  def create_order_stat
    render xml: Order.create_order_stat(params[:order_stat])
  end
  
  def print
    @order = Order.find params[:id]
    data = EasyModel.order_details(@order.code)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      report = EasyReport::Report.new data, 'order_details.yml'
      send_data report.render, filename: "detalle_orden_produccion.pdf", type: "application/pdf"
    end
  end
  
  def show
    order = Order.find params[:id]
    @data = EasyModel.order_details(order.code)
    @parameter_list = ParameterList.includes(:parameters).where(id: order.parameter_list_id).first
  end
end
