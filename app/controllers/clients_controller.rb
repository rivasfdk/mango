# encoding: UTF-8

include MangoModule

class ClientsController < ApplicationController
  def index
    respond_to do |format|
      # Mango
      format.html do
        @clients = Client
          .where(factory: false)
          .order('code ASC')
          .paginate(
            page: params[:page],
            per_page: session[:per_page]
          )
        render html: @clients
      end
      # Romano
      format.json do
        @clients = Client.includes(:addresses).where(factory: false)
        render json: @clients, include: :addresses
      end
    end
  end

  def all
    # Mango
    clients = Client.get_all()
    render json: clients, root: false
  end

  def edit
    @client = Client.find params[:id]
    @multiple_addresses = is_mango_feature_available('multiple_addresses')
  end

  def create
    @client = Client.new params[:client]
    respond_to do |format|
      format.html do
        if @client.save
          flash[:notice] = 'Cliente guardado con éxito'
          redirect_to :clients
        else
          render :new
        end
      end
      format.json do
        if @client.save
          render json: @client, include: :addresses
        else
          render json: @client.errors, status: :unprocessable_entity
        end
      end
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
    if @client.errors.empty?
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

  def get_client
    @client = Client.find params["id_client"]
    render json: @client, root: false
  end

end
