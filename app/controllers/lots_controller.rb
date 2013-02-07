class LotsController < ApplicationController
  def index
    respond_to do |format|
      format.html do 
        @lots = Lot.paginate :all, :page=>params[:page], :per_page=>session[:per_page], :conditions => {:active => true}
        render :html => @lots
      end
      format.json do 
        @lots = Lot.find :all, :conditions => {:active => true}
        render :json => @lots, :methods => [:get_content]
      end
    end
  end

  def new
    @ingredients = Ingredient.find :all, :order => 'name ASC'
    @factories = Client.find :all, :conditions => {:factory => true}
  end

  def edit
    @lot = Lot.find params[:id]
    @ingredients = Ingredient.find :all, :order => 'name ASC'
    @factories = Client.find :all, :conditions => {:factory => true}
  end

  def create
    @lot = Lot.new params[:lot]
    if @lot.save
      flash[:notice] = 'Lote guardado con éxito'
      redirect_to :lots
    else
      new
      render :new
    end
  end

  def update
    @lot = Lot.find params[:id]
    @lot.update_attributes(params[:lot])
    if @lot.save
      flash[:notice] = 'Lote guardado con éxito'
      redirect_to :lots
    else
      render :edit
    end
  end

  def destroy
    @lot = Lot.find params[:id]
    @lot.eliminate
    if @lot.errors.size.zero?
      flash[:notice] = "Lote eliminado con éxito"
    else
      logger.error("Error eliminando lote: #{@lot.errors.inspect}")
      flash[:type] = 'error'
      if not @lot.errors[:foreign_key].nil?
        flash[:notice] = 'El lote no se puede eliminar porque tiene registros asociados'
      elsif not @lot.errors[:unknown].nil?
        flash[:notice] = @lot.errors[:unknown]
      else
        flash[:notice] = "El lote no se ha podido eliminar"
      end
    end
    redirect_to :lots
  end
  
  def adjust
    @lot = Lot.find params[:id]
  end

  def do_adjust
    amount = Float(params[:amount]) rescue -1
    if amount >= 0
      @lot = Lot.get params[:id]
      @lot.adjust(amount, session[:user].id)
      flash[:notice] = "Lote ajustado exitosamente"
      redirect_to :lots
    else
      flash[:type] = 'error'
      flash[:notice] = "El monto de ajuste es inválido"
      redirect_to :lots
    end
  end
end
