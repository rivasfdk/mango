# encoding: UTF-8

include MangoModule

class LotsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @lots = Lot.search(params)
        @ingredients = Ingredient.actives
        @factories = Client.where(factory: true)
        @transactions_enabled = is_mango_feature_available('transactions')
      end
      format.json do
        @lots = Lot.includes(:ingredient)
                   .where(active: true)
                   .order('id desc')
        render json: @lots, methods: [:get_content]
      end
    end
  end

  def get_all
    @lots = Lot.includes(:ingredient)
      .where(active: true)
      .order('id desc')
    render json: @lots, methods: [:to_collection_select], root: false
  end

  def new
    @ingredients = Ingredient.where(empty: nil).order('name ASC')
    @factories = Client.where(factory: true)
    session[:return_to] = request.referer.nil? ? :lots : request.referer
  end

  def edit
    @lot = Lot.find params[:id]
    @ingredients = Ingredient.where(empty: nil).order('name ASC')
    @factories = Client.where(factory: true)
    session[:return_to] = request.referer.nil? ? :lots : request.referer
  end

  def create
    @lot = Lot.new params[:lot]
    if @lot.save
      flash[:notice] = 'Lote guardado con éxito'
      redirect_to session[:return_to]
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
      redirect_to session[:return_to]
    else
      render :edit
    end
  end

  def destroy
    lot_transactions = Transaction.where content_type: 1, content_id: params[:id]
    if lot_transactions.none?
      @lot = Lot.find params[:id]
      @lot.eliminate
      if @lot.errors.empty?
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
      flash[:notice] = "El lote no se puede eliminar porque tiene transacciones asociadas"
    end
    redirect_to :lots
  end
  
  def adjust
    @lot = Lot.find params[:id]
    session[:return_to] = request.referer.nil? ? :lots : request.referer
  end

  def do_adjust
    amount = Float(params[:amount]) rescue 0
    comment = params[:comment]
    @lot = Lot.find params[:id]
    @lot.adjust(amount, session[:user_id], comment)
    flash[:notice] = "Lote ajustado exitosamente"
    redirect_to session.delete(:return_to)
  end
end
