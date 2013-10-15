class LotParameterTypesController < ApplicationController
  def index
    @lot_parameter_types = LotParameterType.paginate :page=>params[:page], :per_page=>session[:per_page]
  end

  def edit
    @lot_parameter_type = LotParameterType.find params[:id]
  end

  def create
    @lot_parameter_type = LotParameterType.new params[:lot_parameter_type]
    if @lot_parameter_type.save
      flash[:notice] = 'Tipo de parámetro guardado con éxito'
      redirect_to :lot_parameter_types
    else
      render :new
    end
  end

  def update
    @lot_parameter_type = LotParameterType.find params[:id]
    @lot_parameter_type.update_attributes(params[:lot_parameter_type])
    if @lot_parameter_type.save
      flash[:notice] = 'Tipo de parámetro actualizado con éxito'
      redirect_to :lot_parameter_types
    else
      render :edit
    end
  end

  def destroy
    @lot_parameter_type = LotParameterType.find params[:id]
    @lot_parameter_type.eliminate
    if @lot_parameter_type.errors.size.zero?
      flash[:notice] = "Tipo de parámetro eliminado con éxito"
    else
      logger.error("Error eliminando tipo de parámetro: #{@lot_parameter_type.errors.inspect}")
      flash[:type] = 'error'
      if not @lot_parameter_type.errors[:foreign_key].nil?
        flash[:notice] = 'El tipo de parámetro no se puede eliminar porque tiene registros asociados'
      elsif not @lot_parameter_type.errors[:unknown].nil?
        flash[:notice] = @lot_parameter_type.errors[:unknown]
      else
        flash[:notice] = "El tipo de parámetro no se ha podido eliminar"
      end
    end
    redirect_to :lot_parameter_types
  end
end
