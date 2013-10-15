class ProductLotParametersController < ApplicationController
  def update
    @product_lot_parameter = ProductLotParameter.find params[:id]
    @product_lot_parameter.update_attributes(params[:product_lot_parameter])
    if @product_lot_parameter.save
      flash[:notice] = 'Característica actualizada con éxito'
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo actualizar la característica"
    end
    redirect_to request.referer
  end
end
