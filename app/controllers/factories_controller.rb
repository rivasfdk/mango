# encoding: UTF-8

class FactoriesController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @factories = Client.paginate :page=>params[:page], :per_page=>session[:per_page], :conditions => {:factory => true}
        render :html => @factories
      end
      format.json do
        @factories = Client.find :all, :conditions => {:factory => true}
        render :json => @factories
      end
    end
  end

  def edit
    @factory = Client.find params[:id]
  end

  def create
    @factory = Client.new params[:client]
    @factory.factory = true
    if @factory.save
      flash[:notice] = 'Fábrica guardada con éxito'
      redirect_to :factories
    else
      render :new
    end
  end

  def update
    @factory = Client.find params[:id]
    @factory.update_attributes(params[:client])
    if @factory.save
      flash[:notice] = 'Fábrica guardada con éxito'
      redirect_to :factories
    else
      render :edit
    end
  end
  
  def destroy
    @factory = Client.find params[:id]
    @factory.eliminate
    if @factory.errors.size.zero?
      flash[:notice] = "Fábrica eliminada con éxito"
    else
      logger.error("Error eliminando fábrica: #{@factory.errors.inspect}")
      flash[:type] = 'error'
      if not @factory.errors[:foreign_key].nil?
        flash[:notice] = 'La fábrica no se puede eliminar porque tiene registros asociados'
      elsif not @factory.errors[:unknown].nil?
        flash[:notice] = @factory.errors[:unknown]
      else
        flash[:notice] = "La fábrica no se ha podido eliminar"
      end
    end
    redirect_to :factories
  end
end
