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
    @warehouse = WarehouseTypes.find(params[:warehouse_type_id]).warehouses.new params[:warehouse]
    if @warehouse.save
      # This should be an after_create callback
      flash[:notice] = 'Almacen guardado con éxito'
      redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
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
      redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
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
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
  end

  def change
    @warehouse = Warehouse.find params[:id]
  end

  def do_change_ingredient
    @warehouse = Warehouse.find params[:id]
    @warehouse.update_attributes(ingredient_id: params[:ingredient_id])
    if @warehouse.valid?
      @warehouse.save
      flash[:notice] = "Cambio de materia prima realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar el ingredient del almacen"
    end
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
  end

  def do_change_product
    @warehouse = Warehouse.find params[:id]
    @warehouse.update_attributes(product_id: params[:product_id])
    if @warehouse.valid?
      @warehouse.save
      flash[:notice] = "Cambio de producto terminado realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar el producto terminado del almacen"
    end
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
  end


  def fill
    @warehouse = Warehouse.find params[:id]
    if @warehouse.stock < 0
      flash[:type] = 'error'
      flash[:notice] = "El almacen tiene existencia negativa, realice un ajuste primero"
      redirect_to warehouse_types_path(@warehouse.warehouse_types_id)
    end
  end

  def do_fill
    @warehouse = Warehouse.find params[:id]
    @warehouse.stock = params[:amount].to_f + @warehouse.stock
    @warehouse.update_attributes(params[:stock])
    if @warehouse.valid?
      @warehouse.save
      flash[:notice] = "Llenado realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo realizar el llenado de la tolva"
  end
    respond_to do |format|
      format.html do
        redirect_to warehouse_type_path(@warehouse.warehouse_types_id) 
      end
      format.xml do
        render xml: {fill: true}
      end
    end
  end

  def adjust
    @warehouse = Warehouse.find params[:id]
  end

  def do_adjust
    @warehouse = Warehouse.find params[:id]
    @warehouse.update_attributes(stock: params[:stock])
    if @warehouse.valid?
      @warehouse.save
      flash[:notice] = "Almacen ajustado exitosamente"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo realizar el ajuste"
    end
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
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