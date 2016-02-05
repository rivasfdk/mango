# encoding: UTF-8

class ParameterTypesController < ApplicationController
  def index
    @parameter_types = ParameterType.paginate :page=>params[:page], :per_page=>session[:per_page]
  end

  def edit
    @parameter_type = ParameterType.find params[:id]
  end

  def create
    @parameter_type = ParameterType.new params[:parameter_type]
    if @parameter_type.save
      flash[:notice] = 'Tipo de parámetro guardado con éxito'
      redirect_to :parameter_types
    else
      render :new
    end
  end

  def update
    @parameter_type = ParameterType.find params[:id]
    @parameter_type.update_attributes(params[:parameter_type])
    if @parameter_type.save
      flash[:notice] = 'Tipo de parámetro actualizado con éxito'
      redirect_to :parameter_types
    else
      render :edit
    end
  end

  def destroy
    @parameter_type = ParameterType.find params[:id]
    @parameter_type.eliminate
    if @parameter_type.errors.empty?
      flash[:notice] = "Tipo de parámetro eliminado con éxito"
    else
      logger.error("Error eliminando tipo de parámetro: #{@parameter_type.errors.inspect}")
      flash[:type] = 'error'
      if not @parameter_type.errors[:foreign_key].nil?
        flash[:notice] = 'El tipo de parámetro no se puede eliminar porque tiene registros asociados'
      elsif not @parameter_type.errors[:unknown].nil?
        flash[:notice] = @parameter_type.errors[:unknown]
      else
        flash[:notice] = "El tipo de parámetro no se ha podido eliminar"
      end
    end
    redirect_to :parameter_types
  end
end
