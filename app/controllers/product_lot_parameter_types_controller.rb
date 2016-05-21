class ProductLotParameterTypesController < ApplicationController
  def index
    @product_lot_parameter_types = ProductLotParameterType.paginate :page=>params[:page], :per_page=>session[:per_page]
  end

  def edit
    @product_lot_parameter_type = ProductLotParameterType.find params[:id]
  end

  def create
    @product_lot_parameter_type = ProductLotParameterType.new params[:product_lot_parameter_type]
    if @product_lot_parameter_type.save
      flash[:notice] = 'Tipo de parámetro guardado con éxito'
      redirect_to :product_lot_parameter_types
    else
      render :new
    end
  end

  def update
    @product_lot_parameter_type = ProductLotParameterType.find params[:id]
    @product_lot_parameter_type.update_attributes(params[:product_lot_parameter_type])
    if @product_lot_parameter_type.save
      flash[:notice] = 'Tipo de parámetro actualizado con éxito'
      redirect_to :product_lot_parameter_types
    else
      render :edit
    end
  end

  def destroy
    @product_lot_parameter_type = ProductLotParameterType.find params[:id]
    @product_lot_parameter_type.eliminate
    if @product_lot_parameter_type.errors.empty?
      flash[:notice] = "Tipo de parámetro eliminado con éxito"
    else
      logger.error("Error eliminando tipo de parámetro: #{@product_lot_parameter_type.errors.inspect}")
      flash[:type] = 'error'
      if not @product_lot_parameter_type.errors[:foreign_key].nil?
        flash[:notice] = 'El tipo de parámetro no se puede eliminar porque tiene registros asociados'
      elsif not @product_lot_parameter_type.errors[:unknown].nil?
        flash[:notice] = @product_lot_parameter_type.errors[:unknown]
      else
        flash[:notice] = "El tipo de parámetro no se ha podido eliminar"
      end
    end
    redirect_to :product_lot_parameter_types
  end
end
