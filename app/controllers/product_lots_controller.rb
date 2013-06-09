# encoding: UTF-8

class ProductLotsController < ApplicationController
  def index
    respond_to do |format|
      format.html do 
        @lots = ProductLot.paginate :page=>params[:page], :per_page=>session[:per_page], :conditions => {:active => true}
        render :html => @lots
      end
      format.json do 
        @lots = ProductLot.find :all, :conditions => {:active => true}
        render :json => @lots, :methods => [:get_content]
      end
    end
  end

  def new
    @products = Product.find :all, :order => 'code ASC'
    @factories = Client.find :all, :conditions => {:factory => true}
  end

  def edit
    @lot = ProductLot.find params[:id]
    @products = Product.find :all, :order => 'code ASC'
    @factories = Client.find :all, :conditions => {:factory => true}
    session[:return_to] = request.referer
  end

  def create
    @lot = ProductLot.new params[:lot]
    if @lot.save
      flash[:notice] = 'ProductLot. guardado con éxito'
      redirect_to :product_lots
    else
      new
      render :new
    end
  end

  def update
    @lot = ProductLot.find params[:id]
    @lot.update_attributes(params[:lot])
    if @lot.save
      flash[:notice] = 'Lote guardado con éxito'
      redirect_to session.delete(:return_to)
    else
      render :edit
    end
  end

  def destroy
    product_lot_transactions = Transaction.where :content_type => 2, :content_id => params[:id]
    if product_lot_transactions.none?
      @lot = ProductLot.find params[:id]
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
    else
      flash[:notice] = 'El lote no se puede eliminar porque tiene transacciones asociadas'
    end
    redirect_to :product_lots
  end

  def adjust
    @product_lot = ProductLot.find params[:id]
    session[:return_to] = request.referer
  end

  def do_adjust
    amount = Float(params[:amount]) rescue -1
    comment = params[:comment]
    if amount >= 0
      @product_lot = ProductLot.find params[:id]
      @product_lot.adjust(amount, session[:user_id], comment)
      flash[:notice] = "Lote ajustado exitosamente"
      redirect_to session.delete(:return_to)
    else
      flash[:type] = 'error'
      flash[:notice] = "El monto de ajuste es inválido"
      redirect_to session.delete(:return_to)
    end
  end
end
