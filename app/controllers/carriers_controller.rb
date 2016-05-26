# encoding: UTF-8

class CarriersController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @carriers = Carrier.order('name ASC')
          .paginate(:page=>params[:page], :per_page=>session[:per_page])
        render :html => @carriers
      end
      format.json do
        @carriers = Carrier.where({:frequent => true})
        render :json => @carriers
      end
    end
  end

  def edit
    @carrier = Carrier.find params[:id]
  end

  def create
    @carrier = Carrier.new params[:carrier]
    respond_to do |format|
      format.html do
        if @carrier.save
          flash[:notice] = 'Empresa de transporte guardada con éxito'
          redirect_to :carriers
        else
          render :new
        end
      end
      format.json do |format|
        if @carrier.save
          render :json => @carrier
        else
          render :json => @carrier.errors, :status => :unprocessable_entity
        end
      end
    end
  end

  def update
    @carrier = Carrier.find params[:id]
    @carrier.update_attributes(params[:carrier])
    if @carrier.save
      flash[:notice] = 'Empresa de transporte guardada con éxito'
      redirect_to :carriers
    else
      edit
      render :edit
    end
  end

  def destroy
    @carrier = Carrier.find params[:id]
    @carrier.eliminate
    if @carrier.errors.empty?
      flash[:notice] = "Empresa de transporte eliminada con éxito"
    else
      logger.error("Error eliminando empresa de transporte: #{@carrier.errors.inspect}")
      flash[:type] = 'error'
      if not @carrier.errors[:foreign_key].nil?
        flash[:notice] = 'La empresa de transporte no se puede eliminar porque tiene registros asociados'
      elsif not @carrier.errors[:unknown].nil?
        flash[:notice] = @carrier.errors[:unknown]
      else
        flash[:notice] = "La empresa de transporte no se ha podido eliminar"
      end
    end
    redirect_to :carriers
  end
end
