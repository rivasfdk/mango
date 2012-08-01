class MixingTimesController < ApplicationController
  def index
    @mixing_times = MixingTime.paginate :all, :page=>params[:page], :per_page=>session[:per_page]
  end
  
  def edit
    @mixing_time = MixingTime.find params[:id]
  end
  
  def create
    @mixing_time = MixingTime.new params[:mixing_time]
    if @mixing_time.save
      flash[:notice] = 'Tiempo de mezcla guardado con éxito'
      redirect_to :mixing_times
    else
      render :new
    end
  end
  
  def update
    @mixing_time = MixingTime.find params[:id]
    @mixing_time.update_attributes(params[:mixing_time])
    if @mixing_time.save
      flash[:notice] = 'Tiempo de mezcla actualizado con éxito'
      redirect_to :mixing_times
    else
      render :edit
    end
  end
  
  def destroy
    @mixing_time = MixingTime.find params[:id]
    @mixing_time.eliminate
    if @mixing_time.errors.size.zero?
      flash[:notice] = "Tiempo de mezcla eliminado con éxito"
    else
      logger.error("Error eliminando el tiempo de mezcla: #{@mixing_time.errors.inspect}")
      flash[:type] = 'error'
      if not @mixing_time.errors[:foreign_key].nil?
        flash[:notice] = 'El tiempo de mezcla no se puede eliminar porque tiene registros asociados'
      elsif not @mixing_time.errors[:unknown].nil?
        flash[:notice] = @mixing_time.errors[:unknown]
      else
        flash[:notice] = "El tiempo de mezcla no se ha podido eliminar"
      end
    end
    redirect_to :mixing_times
  end
end
