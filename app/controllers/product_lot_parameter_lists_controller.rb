class ProductLotParameterListsController < ApplicationController
  def index
    @product_lots = ProductLot.search(params)
    @products = Product.all
    @factories = Client.where(factory: true)
  end

  def show
    @product_lot_parameter_list = ProductLotParameterList.find params[:id],
                                                               :include => {:product_lot_parameters => {:product_lot_parameter_type => {}},
                                                               :product_lot => {:product => {}}}
    @parameters = @product_lot_parameter_list.parameters_with_range
    session[:return_to] = request.referer
  end

  def edit
    @product_lot_parameter_list = ProductLotParameterList.find params[:id],
                                                               :include => {:product_lot_parameters => {:product_lot_parameter_type => {}},
                                                               :product_lot => {:product => {}}}
    session[:return_to] = request.referer
  end

  def update
    @product_lot_parameter_list = ProductLotParameterList.find params[:id]
    @product_lot_parameter_list.update_attributes(params[:product_lot_parameter_list])
    if @product_lot_parameter_list.save
      flash[:notice] = 'Características actualizadas con éxito'
      redirect_to session[:return_to]
    else
      render :edit
    end
  end

  def create
    @product_lot = ProductLot.find params[:product_lot_id]
    if @product_lot.product_lot_parameter_list.nil?
      @product_lot_parameter_list = ProductLotParameterList.new
      @product_lot_parameter_list.product_lot_id = @product_lot.id
      @product_lot_parameter_list.save
      redirect_to edit_product_lot_parameter_list_path(@product_lot_parameter_list)
    else
      redirect_to edit_product_lot_parameter_list_path @product_lot.product_lot_parameter_list
    end
  end
  
  def destroy
    @product_lot_parameter_list = ProductLotParameterList.find params[:id]
    @product_lot_parameter_list.eliminate
    if @product_lot_parameter_list.errors.size.zero?
      flash[:notice] = "Características de lote eliminado con éxito"
    else
      logger.error("Error eliminando características de lote: #{@product_lot_parameter_list.errors.inspect}")
      flash[:type] = 'error'
      if not @product_lot_parameter_list.errors[:foreign_key].nil?
        flash[:notice] = 'Las características del lote no se puede eliminar porque tiene registros asociados'
      elsif not @product_lot_parameter_list.errors[:unknown].nil?
        flash[:notice] = @product_lot_parameter_list.errors[:unknown]
      else
        flash[:notice] = "Las características del lote no se han podido eliminar"
      end
    end
  end
end
