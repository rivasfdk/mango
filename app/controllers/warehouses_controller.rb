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
    @warehouse_types = WarehouseTypes.find params[:warehouse_type_id]
    @warehouse = @warehouse_types.warehouses.create params[:warehouse]
    if @warehouse.save
      @warehouse.set_main_warehouse
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

  def change_ingredient
    @warehouse = Warehouse.find params[:id]
    @lots = Lot.includes(:ingredient)
      .where({:active => true, :in_use => true})
  end

  def do_change_ingredient
    @warehouse = Warehouse.find params[:id]
    new_ingredient = params[:change_ingredient][:new_lot_id]
    new_stock = params[:change_ingredient][:stock]
    if (@warehouse.stock == 0) && (@warehouse.update_attributes(lot_id: new_ingredient, stock: new_stock))
      flash[:notice] = "Cambio de materia prima realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar la materia prima del almacen. Compruebe que la existencia sea nula, de no serlo, realice un ajuste."
    end
    @warehouse.set_main_warehouse
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
  end

  def change_product
    @warehouse = Warehouse.find params[:id]
    @product_lots = ProductLot.includes(:product)
      .where({:active => true, :in_use => true})
  end

  def do_change_product
    @warehouse = Warehouse.find params[:id]
    new_product = params[:change_product][:new_product_lot_id]  # Gets new product chosen by user
    new_stock = params[:change_product][:stock]
    if (@warehouse.stock == 0) && (@warehouse.update_attributes(product_lot_id: new_product, stock: new_stock)) 
      flash[:notice] = "Cambio de producto terminado realizado con éxito"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo cambiar el producto terminado del almacen. Compruebe que la existencia sea nula, de no serlo, realice un ajuste."
    end
    @warehouse.set_main_warehouse
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
    new_stock = params[:do_fill][:amount].to_f + @warehouse.stock
    if @warehouse.update_attributes(stock: new_stock)
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
    WarehouseTransactions.create transaction_type_id: @warehouse.stock < params[:stock].to_f ? 2 : 3,
                                 warehouse_id: @warehouse.id,
                                 amount: params[:stock].to_f,
                                 stock_after: params[:stock].to_f,
                                 lot_id: @warehouse.lot_id.nil? ? @warehouse.product_lot_id : @warehouse.lot_id,
                                 content_type: @warehouse.warehouse_types.content_type,
                                 user_id: session[:user_id]
    @warehouse.update_attributes(stock: params[:stock])
    if @warehouse.save
      flash[:notice] = "Almacen ajustado exitosamente"
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo realizar el ajuste"
    end
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
  end

  def sacks
    @warehouse = Warehouse.find params[:id], :include => :warehouses_contents
    @lots = Lot.includes(:ingredient).where(active: true, in_use: true, empty: nil)
    @product_lots = ProductLot.includes(:product).where(active: true, in_use: true, empty: nil)
  end

  def set_as_main_warehouse
    @warehouse = Warehouse.find params[:id]
    @warehouse.set_as_main_warehouse()
    redirect_to warehouse_type_path(@warehouse.warehouse_types_id)
  end

  private

  def fill_new
    @warehouse_types = WarehouseTypes.find params[:warehouse_type_id]
    @warehouse = @warehouse_types.warehouses.build
    @lots = Lot.includes(:ingredient)
      .where({:active => true, :in_use => true})
    @product_lots = ProductLot.includes(:product)
      .where({:active => true, :in_use => true})
  end

  def fill_edit
    @warehouse_types = WarehouseTypes.find params[:warehouse_type_id]
    @warehouse = @warehouse_types.warehouses.find params[:id]
    @lots = Lot.includes(:ingredient)
      .where({:active => true, :in_use => true})
    @product_lots = ProductLot.includes(:product)
      .where({:active => true, :in_use => true})
  end

end