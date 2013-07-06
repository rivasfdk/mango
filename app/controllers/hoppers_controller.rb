# encoding: UTF-8

class HoppersController < ApplicationController
  def index
    redirect_to scale_path(params[:scale_id])
  end

  def new
    @lots = Lot.where :active => true, :in_use => true
    session[:return_to] = request.referer
  end

  def edit
    @lots = Lot.where :active => true, :in_use => true
    @hopper = Hopper.find params[:id]
    @current_lot = @hopper.find_active.lot rescue nil
    session[:return_to] = request.referer
  end

  def create
    @hopper = Hopper.new :number => params[:hopper][:number], :scale_id => params[:scale_id]
    if @hopper.save
      if @hopper.update_lot(params[:hopper][:hopper_lot]) and @hopper.update_name(params[:hopper][:name])
        flash[:notice] = 'Tolva guardada con éxito'
      else
        flash[:notice] = 'La tolva fue guardada con éxito pero no se guardó el ingrediente asociado'
      end
      redirect_to session[:return_to]
    else
      new
      render :new
    end
  end

  def update
    @hopper = Hopper.find params[:id]
    if @hopper.update_lot(params[:hopper][:hopper_lot]) and @hopper.update_name(params[:hopper][:name])
      flash[:notice] = 'Tolva actualizada con éxito'
      redirect_to session[:return_to]
    else
      edit
      render :edit
    end
  end

  def destroy
    @hopper = Hopper.find params[:id]
    @hopper.eliminate
    if @hopper.errors.size.zero?
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
    redirect_to request.referer
  end

  private

  def fill
    @lots
  end
end
