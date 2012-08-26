class ClientsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @clients = Client.paginate :all, :page=>params[:page], :per_page=>session[:per_page], :conditions => {:factory => false}, :order => ['code ASC']
        render :html => @clients
      end
      format.json do
        @clients = Client.find :all, :conditions => {:factory => false}
        render :json => @clients
      end
    end
  end

  def edit
    @client = Client.find params[:id]
  end

  def create
    @client = Client.new params[:client]
    @client.factory = false
    if @client.save
      flash[:notice] = 'Cliente guardado con éxito'
      redirect_to :clients
    else
      render :new
    end
  end

  def update
    @client = Client.find params[:id]
    @client.update_attributes(params[:client])
    if @client.save
      flash[:notice] = 'Cliente guardado con éxito'
      redirect_to :clients
    else
      render :edit
    end
  end
  
  def destroy
    @client = Client.find params[:id]
    @client.eliminate
    if @client.errors.size.zero?
      flash[:notice] = "Cliente eliminado con éxito"
    else
      logger.error("Error eliminando cliente: #{@client.errors.inspect}")
      flash[:type] = 'error'
      if not @client.errors[:foreign_key].nil?
        flash[:notice] = 'El cliente no se puede eliminar porque tiene registros asociados'
      elsif not @client.errors[:unknown].nil?
        flash[:notice] = @client.errors[:unknown]
      else
        flash[:notice] = "El cliente no se ha podido eliminar"
      end
    end
    redirect_to :clients
  end
end
