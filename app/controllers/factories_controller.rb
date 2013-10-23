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
    @client = Client.new params[:client]
    @client.factory = true
    if @client.save
      flash[:notice] = 'Fábrica guardada con éxito'
      redirect_to :factories
    else
      render :new
    end
  end

  def update
    @client = Client.find params[:id]
    @client.update_attributes(params[:client])
    if @client.save
      flash[:notice] = 'Fábrica guardada con éxito'
      redirect_to :factories
    else
      render :edit
    end
  end
  
  def destroy
    @client = Client.find params[:id]
    @client.eliminate
    if @client.errors.size.zero?
      flash[:notice] = "Fábrica eliminada con éxito"
    else
      logger.error("Error eliminando fábrica: #{@client.errors.inspect}")
      flash[:type] = 'error'
      if not @client.errors[:foreign_key].nil?
        flash[:notice] = 'La fábrica no se puede eliminar porque tiene registros asociados'
      elsif not @client.errors[:unknown].nil?
        flash[:notice] = @client.errors[:unknown]
      else
        flash[:notice] = "La fábrica no se ha podido eliminar"
      end
    end
    redirect_to :factories
  end
end
