# encoding: UTF-8

class OrderStatTypesController < ApplicationController
  def index
    @order_stat_types = OrderStatType.includes(:area)
    @units = OrderStatType::UNITS
  end

  def new
    @areas = Area.all
    @units = OrderStatType::UNITS
  end

  def edit
    new
    @order_stat_type = OrderStatType.find params[:id]
  end

  def create
    @order_stat_type = OrderStatType.new params[:order_stat_type]
    if @order_stat_type.save
      flash[:notice] = 'Tipo de estadística guardada con éxito'
      redirect_to :order_stat_types
    else
      render :new
    end
  end

  def update
    @order_stat_type = OrderStatType.find params[:id]
    @order_stat_type.update_attributes(params[:order_stat_type])
    if @order_stat_type.save
      flash[:notice] = 'Tipo de estadística actualizada con éxito'
      redirect_to :order_stat_types
    else
      render :edit
    end
  end

  def destroy
    @order_stat_type = OrderStatType.find params[:id]
    @order_stat_type.eliminate
    if @order_stat_type.errors.empty?
      flash[:notice] = "Tipo de estadística eliminada con éxito"
    else
      logger.error("Error eliminando tipo de order_stata: #{@order_stat_type.errors.inspect}")
      flash[:type] = 'error'
      if not @order_stat_type.errors[:foreign_key].nil?
        flash[:notice] = 'El tipo de estadística no se puede eliminar porque tiene registros asociados'
      elsif not @order_stat_type.errors[:unknown].nil?
        flash[:notice] = @order_stat_type.errors[:unknown]
      else
        flash[:notice] = "El tipo de estadística no se ha podido eliminar"
      end
    end
    redirect_to :order_stat_types
  end
end
