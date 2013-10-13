class LotParametersController < ApplicationController
  def update
    @lot_parameter = LotParameter.find params[:id]
    @lot_parameter.update_attributes(params[:lot_parameter])
    if @lot_parameter.save
      flash[:notice] = 'Característica actualizada con éxito'
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo actualizar la característica"
    end
    redirect_to request.referer
  end
end
