# encoding: UTF-8

include MangoModule

class WarehousesController < ApplicationController
  def index
    redirect_to warehouse_types_path(params[:warehouse_types_id])
  end

  def new
    fill_new
  end

  def edit
    fill_edit
  end

  def create
    @warehouse = WarehouseTypes.find(params[:warehouse_types_id]).warehouses.new params[:warehouse]
    if @warehouse.save
      # This should be an after_create callback
      flash[:notice] = 'Almacen guardado con éxito'
      redirect_to warehouse_types_path(@warehouse.warehouse_types_id)
    else
      fill_new
      render :new
    end
  end

  def update
    @warehouse = Warehouse.find params[:id]
    @warehouse.update_attributes(params[:warehouse])
    if @warehouse.save
      flash[:notice] = 'Almacen actualizado con éxito'
      redirect_to warehouse_types_path(@warehouse.warehouse_types_id)
    else
      fill_edit
      render :edit
    end
  end

  def destroy
    @warehouse = Warehouse.find params[:id]
    @warehouse.eliminate
    if @warehouse.errors.empty?
      flash[:notice] = "Alamacen eliminado con éxito"
    else
      logger.error("Error eliminando almacen: #{@warehouse.errors.inspect}")
      flash[:type] = 'error'
      if not @warehouse.errors[:foreign_key].nil?
        flash[:notice] = 'El almacen no se puede eliminar porque tiene registros asociados'
      elsif not @warehouse.errors[:unknown].nil?
        flash[:notice] = @warehouse.errors[:unknown]
      else
        flash[:notice] = "El almacen no se ha podido eliminar"
      end
    end
    redirect_to warehouse_types_path(@warehouse.warehouse_types_id)
  end

  def change
    @warehouse = Warehouse.find params[:id]
  end

  def do_change
    @warehouse = Warehouse.find params[:id]
    if @warehouse.change(params[:change], session[:user_id])
      flash[:notice] = "Cambio de ingrediente realizado con éxito"
      current_hopper_lot = @hopper.current_hopper_lot
      factory_lots = Lot.where(['client_id is not null and active = true and in_use = true and ingredient_id = ?', current_hopper_lot.lot.ingredient_id]).count
      redirect_to warehouse_types_path(@warehouse.warehouse_types_id)
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar el ingrediente del almacen"
      redirect_to warehouse_path(@warehouse.warehouse_types_id)
    end
  end

  def adjust
    @warehouse = Warehouse.find params[:id]
  end

  def do_adjust
    @warehouse = Warehouse.find params[:id]
    if @warehouse.adjust(params[:adjust], session[:user_id])
      flash[:notice] = "Ajuste realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo realizar el ajuste"
    end
    redirect_to warehouse_types_path(@warehouse.warehouse_types_id)
  end

  private

  def fill_new
    @warehouse_types = WarehouseTypes.all
  end

  def fill_edit
    @warehouse_types = WarehouseTypes.all
    @warehouse = Warehouse.find params[:id]
  end
end