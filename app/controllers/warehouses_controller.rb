include MangoModule

class WarehousesController < ApplicationController

  def index
    @warehouses = Warehouse.search(params)
  end

  def create
    @s = Warehouse.new params[:warehouse]
    if @warehouses.save
      flash[:notice] = 'Almacen guardado con éxito'
      redirect_to :warehouses
    else
      render :new
    end
  end

  def edit
    @warehouses = Warehouse.find params[:id]
  end

  def update
    @warehouses = Warehouse.find params[:id]
    @warehouses.update_attributes(params[:warehouse])
    if @warehouses.save
      flash[:notice] = 'Almacen de materia prima actualizado con éxito'
      redirect_to :warehouses
    else
      render :edit
    end
  end

  def destroy
    @warehouse = Warehouse.find params[:id]
    @warehouse.eliminate
    if @warehouse.errors.empty?
      flash[:notice] = "alamcen de materia prima eliminada con éxito"
    else
      logger.error("Error eliminando almacen: #{@warehouses.errors.inspect}")
      flash[:type] = 'error'
      if not @warehouse.errors[:foreign_key].nil?
        flash[:notice] = 'El almacen no se puede eliminar porque tiene ingredientes asociados'
      elsif not @warehouse.errors[:unknown].nil?
        flash[:notice] = @warehouses.errors[:unknown]
      else
        flash[:notice] = "El almacen no se ha podido eliminar"
      end
    end
    redirect_to :warehouses
  end

end
