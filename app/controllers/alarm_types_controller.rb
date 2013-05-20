class AlarmTypesController < ApplicationController
  def index
    @alarm_types = AlarmType.paginate :all, :page=>params[:page], :per_page=>session[:per_page]
  end

  def edit
    @alarm_type = AlarmType.find params[:id]
  end

  def create
    @alarm_type = AlarmType.new params[:alarm_type]
    if @alarm_type.save
      flash[:notice] = 'Tipo de alarma guardada con éxito'
      redirect_to :alarm_types
    else
      render :new
    end
  end

  def update
    @alarm_type = AlarmType.find params[:id]
    @alarm_type.update_attributes(params[:alarm_type])
    if @alarm_type.save
      flash[:notice] = 'Tipo de alarma actualizada con éxito'
      redirect_to :alarm_types
    else
      render :edit
    end
  end

  def destroy
    @alarm_type = AlarmType.find params[:id]
    @alarm_type.eliminate
    if @alarm_type.errors.size.zero?
      flash[:notice] = "Tipo de alarma eliminada con éxito"
    else
      logger.error("Error eliminando tipo de alarma: #{@alarm_type.errors.inspect}")
      flash[:type] = 'error'
      if not @alarm_type.errors[:foreign_key].nil?
        flash[:notice] = 'El tipo de alarma no se puede eliminar porque tiene registros asociados'
      elsif not @alarm_type.errors[:unknown].nil?
        flash[:notice] = @alarm_type.errors[:unknown]
      else
        flash[:notice] = "El tipo de alarma no se ha podido eliminar"
      end
    end
    redirect_to :alarm_types
  end
end
