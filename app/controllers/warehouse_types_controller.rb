# encoding: UTF-8

include MangoModule

class WarehouseTypesController < ApplicationController
  def index
    redirect_to warehouse_path(params[:warehouse_id])
  end

  def new
    fill_new
  end

  def edit
    fill_edit
  end

  def create
    @warehouse_type = Warehouse.find(params[:warehouse_id]).warehouse_types.new params[:warehouse_type]
    if @warehouse_type.save
      # This should be an after_create callback
      flash[:notice] = 'Almacen guardado con éxito'
      redirect_to warehouse_path(@warehouse_type.warehouse_id)
    else
      fill_new
      render :new
    end
  end

  def update
    @warehouse_type = WarehouseType.find params[:id]
    @warehouse_type.update_attributes(params[:warehouse_type])
    if @warehouse_type.save
      flash[:notice] = 'Almacen actualizado con éxito'
      redirect_to warehouse_path(@warehouse_type.warehouse_id)
    else
      fill_edit
      render :edit
    end
  end

  # def set_as_main_hopper
  #   @hopper = Hopper.find params[:id]
  #   @hopper.set_as_main_hopper()
  #   redirect_to scale_path(@hopper.scale_id)
  # end

  def destroy
    @warehouse_type = WarehouseType.find params[:id]
    @warehouse_type.eliminate
    if @warehouse_type.errors.empty?
      flash[:notice] = "Alamacen eliminado con éxito"
    else
      logger.error("Error eliminando almacen: #{@warehouse_type.errors.inspect}")
      flash[:type] = 'error'
      if not @warehouse_type.errors[:foreign_key].nil?
        flash[:notice] = 'El almacen no se puede eliminar porque tiene registros asociados'
      elsif not @warehouse_type.errors[:unknown].nil?
        flash[:notice] = @warehouse_type.errors[:unknown]
      else
        flash[:notice] = "El almacen no se ha podido eliminar"
      end
    end
    redirect_to warehouse_path(@warehouse_type.warehouse_id)
  end

  def change
    @warehouse_type = WarehouseType.find params[:id]
  end

  def do_change
    @warehouse_type = WarehouseType.find params[:id]
    if @warehouse_type.change(params[:change], session[:user_id])
      flash[:notice] = "Cambio de ingrediente realizado con éxito"
      current_hopper_lot = @hopper.current_hopper_lot
      factory_lots = Lot.where(['client_id is not null and active = true and in_use = true and ingredient_id = ?', current_hopper_lot.lot.ingredient_id]).count
      redirect_to scale_path(@hopper.scale_id)
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar el ingrediente del almacen"
      redirect_to warehouse_path(@warehouse_type.warehouse_id)
    end
  end

  def adjust
    @warehouse_type = WarehouseType.find params[:id]
  end

  def do_adjust
    @warehouse_types = WarehouseType.find params[:id]
    if @warehouse_type.adjust(params[:adjust], session[:user_id])
      flash[:notice] = "Ajuste realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo realizar el ajuste"
    end
    redirect_to warehouse_path(@warehouse_type.warehouse_id)
  end

  private

  def fill_new
    @warehouses = Warehouse.all
  end

  def fill_edit
    @warehouses = Warehouse.all
    @warehouse_type = WarehouseType.find params[:id]
  end
end
