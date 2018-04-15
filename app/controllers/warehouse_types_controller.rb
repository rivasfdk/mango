include MangoModule

class WarehouseTypesController < ApplicationController

  def index
    @warehouse_types = WarehouseTypes.search(params)
  end

  def show
    @warehouse_type = WarehouseTypes.find params[:id]
    if @warehouse_type.content_type
      @warehouses = @warehouse_type.warehouses :include => :lots
    else
      @warehouses = @warehouse_type.warehouses :include => :product_lots
    end
  end

  def create
    @warehouse_types = WarehouseTypes.new params[:warehouse_types]
    if @warehouse_types.save
      flash[:notice] = 'Almacen guardado con éxito'
      redirect_to :warehouse_types
    else
      render :new
    end
  end

  def edit
    @warehouse_types = WarehouseTypes.find params[:id]
  end

  def update
    @warehouse_types = WarehouseTypes.find params[:id]
    @warehouse_types.update_attributes(params[:warehouse_types])
    if @warehouse_types.save
      flash[:notice] = 'Almacen actualizado con éxito'
      redirect_to :warehouse_types
    else
      render :edit
    end
  end

  def destroy
    @warehouse_types = WarehouseTypes.find params[:id]
    @warehouse_types.eliminate
    if @warehouse_types.errors.empty?
      flash[:notice] = "Almacen eliminado con éxito"
    else
      logger.error("Error eliminando almacen: #{@warehouse_types.errors.inspect}")
      flash[:type] = 'error'
      if not @warehouse_types.errors[:foreign_key].nil?
        flash[:notice] = 'El almacen no se puede eliminar porque tiene ingredientes asociados'
      elsif not @warehouse_types.errors[:unknown].nil?
        flash[:notice] = @warehouse_types.errors[:unknown]
      else
        flash[:notice] = "El almacen no se ha podido eliminar"
      end
    end
    redirect_to :warehouse_types
  end

  def warehouses_products
    render xml: WarehouseTypes.get_warehouses_products, root: 'warehouses_types'
  end

end