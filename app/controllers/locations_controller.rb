# Maintenance Module  

include MangoModule

class LocationsController < ApplicationController

  def index
    @locations = Location.search(params)
  end

  def show
    @locations = Location.find params[:id]
    @machines = @locations.machines
  end

  def create
    @location = Location.new params[:location]
    if @location.save
      flash[:notice] = 'Ubicación guardada con éxito'
      redirect_to :locations
    else
      render :new
    end
  end

  def edit
    @location = Location.find params[:id]
  end

  def update
    @location = Location.find params[:id]
    @location.update_attributes(params[:location])
    if @location.save
      flash[:notice] = 'Ubicación guardada con éxito'
      redirect_to :locations
    else
      render :edit
    end
  end

  def destroy
    @location = Location.find params[:id]
    @location.eliminate
    if @location.errors.empty?
      flash[:notice] = "Ubicación eliminada con éxito"
    else
      logger.error("Error eliminando ubicación: #{@location.errors.inspect}")
      flash[:type] = 'error'
      if not @location.errors[:unknown].nil?
        flash[:notice] = @location.errors[:unknown]
      else
        flash[:notice] = "La ubicación no se ha podido eliminar"
      end
    end
    redirect_to :locations
  end
  
end
