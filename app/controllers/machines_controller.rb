class MachinesController < ApplicationController

  def index
    redirect_to location_path(params[:location_id])
  end

  def new
    fill_new
  end

  def edit
    fill_edit
  end

  def create
    @location = Location.find params[:location_id]
    @machine = @location.machines.create(params[:machine])
    if @machine.save
      flash[:notice] = 'Máquina guardada con éxito'
      redirect_to locations_path(@location)
    else
      render :new
    end
  end

  def update
    @machine = Machine.find params[:id]
    @machine.update_attributes(params[:machine])
    if @machine.save
      flash[:notice] = 'Máquina actualizado con éxito'
      redirect_to location_path(@machine.location_id)
    else
      render :edit
    end
  end

  def destroy
    @machine = Machine.find params[:id]
    @machine.eliminate
    if @machine.errors.empty?
      flash[:notice] = "Máquina eliminada con éxito"
    else
      logger.error("Error eliminando máquina: #{@machine.errors.inspect}")
      flash[:type] = 'error'
      if not @machine.errors[:unknown].nil?
        flash[:notice] = machine.errors[:unknown]
      else
        flash[:notice] = "La máquina no se ha podido eliminar"
      end
    end
    redirect_to location_path(@machine.location_id)
  end

  def fill_hours
    @location = Location.find params[:location_id]
    @machine = @location.machines.find params[:id]
  end

  def do_fill_hours
    @machine = Machine.find params[:id]
    new_hours = params[:do_fill_hours][:new_hours].to_f + @machine.hours
    if @machine.update_attributes(hours: new_hours)
      flash[:notice] = "Aumento de horas realizado con éxito."
      redirect_to location_path(@machine.location_id)
    else
      render :fill_hours
    end
  end

  private

  def fill_new
    @location = Location.find params[:location_id]
    @machine = @location.machines.build
  end

  def fill_edit
    @location = Location.find params[:location_id]
    @machine = @location.machines.find params[:id]
  end

end

