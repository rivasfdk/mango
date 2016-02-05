# encoding: UTF-8

class ParametersController < ApplicationController
  def create
    unless params[:parameter][:parameter_type_id].blank?
      parameter = Parameter.new
      parameter.parameter_list_id = params[:parameter_list_id]
      parameter.parameter_type_id = params[:parameter][:parameter_type_id]
      parameter.value = params[:parameter][:value]
      if parameter.valid?
        parameter.save
        flash[:notice] = "Parámetro agregado a la receta"
      else
        logger.error("No se pudo guardar el parámetro: #{parameter.errors.inspect}")
        flash[:notice] = "No se pudo guardar el parámetro"
        flash[:type] = 'error'
      end
    else
      flash[:notice] = "Por favor seleccione un tipo de parámetro válido"
      flash[:type] = 'error'
    end
    redirect_to request.referer + "#parameters"
  end

  def destroy
    @parameter = Parameter.find params[:id]
    @parameter.eliminate
    if @parameter.errors.empty?
      flash[:notice] = "Parámetro eliminado de la receta con éxito"
    else
      logger.error("Error eliminando parámetro de la receta: #{@parameter.errors.inspect}")
      flash[:type] = 'error'
      flash[:notice] = "No se pudo borrar el parámetro de la receta"
    end
    redirect_to request.referer + "#parameters"
  end

  def update
    @parameter = Parameter.find params[:id]
    @parameter.update_attributes(params[:parameter])
    if @parameter.save
      flash[:notice] = 'Parámetro actualizado con éxito'
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo actualizar el parámetro"
    end
    redirect_to request.referer + "#parameters"
  end
end
