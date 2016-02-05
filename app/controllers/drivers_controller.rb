# encoding: UTF-8

class DriversController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @drivers = Driver.paginate :page=>params[:page], :per_page=>session[:per_page], :conditions => {:frequent => true}, :order => 'name ASC'
        render :html => @drivers
      end
      format.json do
        @drivers = Driver.where({:frequent => true})
        render :json => @drivers
      end
    end
  end

  def edit
    @driver = Driver.find params[:id]
  end

  def create
    @driver = Driver.new params[:driver]
    respond_to do |format|
      format.html do
        if @driver.save
          flash[:notice] = 'Chofer guardado con éxito'
          redirect_to :drivers
        else
          render :new
        end
      end
      format.json do
        if @driver.save
          render :json => @driver
        else
          render :json => @driver.errors, :status => :unprocessable_entity
        end
      end
    end
  end

  def update
    @driver = Driver.find params[:id]
    @driver.update_attributes(params[:driver])
    if @driver.save
      flash[:notice] = 'Chofer guardado con éxito'
      redirect_to :drivers
    else
      edit
      render :edit
    end
  end

  def destroy
    @driver = Driver.find params[:id]
    @driver.eliminate
    if @driver.errors.empty?
      flash[:notice] = "Chofer eliminado con éxito"
    else
      logger.error("Error eliminando chofer: #{@driver.errors.inspect}")
      flash[:type] = 'error'
      if not @driver.errors[:foreign_key].nil?
        flash[:notice] = 'El chofer no se puede eliminar porque tiene registros asociados'
      elsif not @driver.errors[:unknown].nil?
        flash[:notice] = @driver.errors[:unknown]
      else
        flash[:notice] = "El chofer no se ha podido eliminar"
      end
    end
    redirect_to :drivers
  end
end
