# encoding: UTF-8

include MangoModule

class HoppersController < ApplicationController
  def index
    redirect_to scale_path(params[:scale_id])
  end

  def new
    fill_new
  end

  def edit
    fill_edit
  end

  def create
    @hopper = Scale.find(params[:scale_id]).hoppers.new params[:hopper]
    if @hopper.save
      Log.create type_id: 5, user_id: session[:user_id], 
                 action: "Tolva CREADA: #{@hopper.name} codigo: #{@hopper.code} balanza: #{@hopper.scale.name}"
      # This should be an after_create callback
      @hopper_lot = @hopper.hopper_lot.new params[:hopper_lot]
      @hopper_lot.save
      flash[:notice] = 'Tolva guardada con éxito'
      redirect_to scale_path(@hopper.scale_id)
    else
      fill_new
      render :new
    end
  end

  def update
    @hopper = Hopper.find params[:id]
    @hopper.update_attributes(params[:hopper])
    error = @hopper.validate_priority(params[:old_priority])
    if error.empty?
      if @hopper.save
        Log.create type_id: 5, user_id: session[:user_id], 
                  action: "Tolva EDITADA: #{@hopper.name} codigo: #{@hopper.code} balanza: #{@hopper.scale.name}"
        flash[:notice] = 'Tolva actualizada con éxito'
        redirect_to scale_path(@hopper.scale_id)
      else
        fill_edit
        render :edit
      end
    else
      flash[:type] = 'error'
      flash[:notice] = error
      redirect_to scale_path(@hopper.scale_id)
    end
  end

  def set_as_main_hopper
    @hopper = Hopper.find params[:id]
    @hopper.set_as_main_hopper()
    redirect_to scale_path(@hopper.scale_id)
  end

  def change_main
    hopper1 = Hopper.where(scale_id: params[:scale][:scale_id], number: params[:scale][:tolva1]).first
    hopper2 = Hopper.where(scale_id: params[:scale][:scale_id], number: params[:scale][:tolva2]).first
    priorityhopper1 = hopper1.priority
    hopper1.update_attributes(priority: hopper2.priority)
    hopper2.update_attributes(priority: priorityhopper1)
    hopper2.set_as_main_hopper()
    render xml: {success: true}
  end

  def destroy
    @hopper = Hopper.find params[:id]
    @hopper.eliminate
    if @hopper.errors.empty?
      Log.create type_id: 5, user_id: session[:user_id], 
                 action: "Tolva ELIMINADA: #{@hopper.name} codigo: #{@hopper.code} balanza: #{@hopper.scale.name}"
      flash[:notice] = "Tolva eliminada con éxito"
    else
      logger.error("Error eliminando tolva: #{@hopper.errors.inspect}")
      flash[:type] = 'error'
      if not @hopper.errors[:foreign_key].nil?
        flash[:notice] = 'La tolva no se puede eliminar porque tiene registros asociados'
      elsif not @hopper.errors[:unknown].nil?
        flash[:notice] = @hopper.errors[:unknown]
      else
        flash[:notice] = "La tolva no se ha podido eliminar"
      end
    end
    redirect_to scale_path(@hopper.scale_id)
  end

  def change
    @hoppers_transactions_enabled = is_mango_feature_available("hoppers_transactions")
    @hopper = Hopper.find params[:id]
    @current_lot = @hopper.current_lot
    @lots = Lot
      .includes(:ingredient)
      .where(active: true, in_use: true)
      .where('client_id is null')
  end

  def do_change
    @hopper = Hopper.find params[:id]
    params[:change][:amount] = 0 unless is_mango_feature_available("hoppers_transactions")
    old_lot = "#{@hopper.current_lot.ingredient.code} - #{@hopper.current_lot.ingredient.name} (L: #{@hopper.current_lot.code})"
    if @hopper.change(params[:change], session[:user_id])
      new_lot = "#{@hopper.current_lot.ingredient.code} - #{@hopper.current_lot.ingredient.name} (L: #{@hopper.current_lot.code})"
      Log.create type_id: 5, user_id: session[:user_id], 
                 action: "Tolva CAMBIO de lote: #{@hopper.name} codigo: #{@hopper.code} balanza: #{@hopper.scale.name}\n"+
                 "lote anterior: #{old_lot}\n"+
                 "lote nuevo: #{new_lot}"
      flash[:notice] = "Cambio de lote realizado con éxito"
      current_hopper_lot = @hopper.current_hopper_lot
      factory_lots = Lot.where(['client_id is not null and active = true and in_use = true and ingredient_id = ?', current_hopper_lot.lot.ingredient_id]).count
      if factory_lots > 0
        redirect_to change_factory_lots_scale_hopper_path(@hopper.scale_id, @hopper.id)
      else
        redirect_to scale_path(@hopper.scale_id)
      end
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar el lote de la tolva"
      redirect_to scale_path(@hopper.scale_id)
    end
  end

  def adjust
    @hopper = Hopper.find params[:id]
    @current_hopper_lot = @hopper.current_hopper_lot
    if @current_hopper_lot.lot_id == 1
      flash[:type] = 'error'
      flash[:notice] = "No hay asignado ningún ingrediente en la tolva"
      redirect_to scale_path(@hopper.scale_id)
    end
  end

  def do_adjust
    @hopper = Hopper.find params[:id]
    if @hopper.adjust(params[:adjust], session[:user_id])
      flash[:notice] = "Ajuste realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo realizar el ajuste"
    end
    redirect_to scale_path(@hopper.scale_id)
  end

  def fill
    @hopper = Hopper.find params[:id]
    @current_hopper_lot = @hopper.current_hopper_lot
    if @current_hopper_lot.stock < 0
      flash[:type] = 'error'
      flash[:notice] = "La tolva tiene existencia negativa, realice un ajuste primero"
      redirect_to scale_path(@hopper.scale_id)
    end
    if @current_hopper_lot.lot_id == 1
      flash[:type] = 'error'
      flash[:notice] = "No hay asignado ningún ingrediente en la tolva"
      redirect_to scale_path(@hopper.scale_id)
    end
  end

  def do_fill
    @hopper = Hopper.find params[:id]
    if @hopper.fill(params[:fill], session[:user_id])
      respond_to do |format|
        format.html do
          flash[:notice] = "Llenado de la tolva realizado con éxito"
          redirect_to scale_path(@hopper.scale_id)  
        end
        format.xml do
          render xml: {fill: true}
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:type] = 'error'
          flash[:notice] = "No se pudo realizar el llenado de la tolva"
          redirect_to scale_path(@hopper.scale_id) 
        end
        format.xml do
          render xml: {fill: false}
        end
      end 
    end 
  end

  def change_factory_lots
    @hopper = Hopper.find params[:id]
    @current_hopper_lot = @hopper.current_hopper_lot
    @current_hopper_lot.generate_hoppers_factory_lots if @current_hopper_lot.hoppers_factory_lots.count == 0
    @factory_lots = Lot.find_by_factory(@current_hopper_lot.lot)
  end

  def do_change_factory_lots
    @hopper = Hopper.find params[:id]
    @current_hopper_lot = @hopper.current_hopper_lot
    @current_hopper_lot.update_attributes(params[:hopper_lot])
    if @current_hopper_lot.save
      flash[:notice] = "Lotes por fábrica actualizados con éxito"
      redirect_to scale_path(@hopper.scale_id)
    else
      change_factory_lots
      render :change_factory_lots
    end
  end

  private

  def fill_new
    @hoppers_transactions_enabled = is_mango_feature_available("hoppers_transactions")
    @lots = Lot.includes(:ingredient)
      .where({:active => true, :in_use => true})
    @scales = Scale.all
  end

  def fill_edit
    @hoppers_transactions_enabled = is_mango_feature_available("hoppers_transactions")
    @scales = Scale.all
    @hopper = Hopper.find params[:id]
  end
end
