class TrucksController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @trucks = Truck.paginate :all, :page=>params[:page], :per_page=>session[:per_page], :conditions => {:frequent => true}
        render :html => @trucks
      end
      format.json do
        @trucks = Truck.find :all, :conditions => {:frequent => true}
        render :json => @trucks, :include => :carrier
      end
    end
  end

  def new
    @carriers = Carrier.find :all
  end

  def edit
    @truck = Truck.find params[:id]
    @carriers = Carrier.find :all
  end

  def create
    @truck = Truck.new params[:truck]
    respond_to do |format|
      format.html do
        if @truck.save
          flash[:notice] = 'Camión guardado con éxito'
          redirect_to :trucks
        else
          new
          render :new
        end
      end
      format.json do
        if @truck.save
          render :json => @truck, :include => :carrier
        else
          render :json => @truck.errors, :status => :unprocessable_entity
        end
      end
    end
  end

  def update
    @truck = Truck.find params[:id]
    @truck.update_attributes(params[:truck])
    if @truck.save
      flash[:notice] = 'Camión guardado con éxito'
      redirect_to :trucks
    else
      edit
      render :edit
    end
  end

  def destroy
    @truck = Truck.find params[:id]
    @truck.eliminate
    if @truck.errors.size.zero?
      flash[:notice] = "Camión eliminado con éxito"
    else
      logger.error("Error eliminando camión: #{@truck.errors.inspect}")
      flash[:type] = 'error'
      if not @truck.errors[:foreign_key].nil?
        flash[:notice] = 'El camión no se puede eliminar porque tiene registros asociados'
      elsif not @truck.errors[:unknown].nil?
        flash[:notice] = @truck.errors[:unknown]
      else
        flash[:notice] = "El camión no se ha podido eliminar"
      end
    end
    redirect_to :trucks
  end
end
