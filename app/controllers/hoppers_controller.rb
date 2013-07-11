# encoding: UTF-8

class HoppersController < ApplicationController
  def index
    redirect_to scale_path(params[:scale_id])
  end

  def new
    fill_new
    session[:return_to] = request.referer
  end

  def edit
    fill_edit
    session[:return_to] = request.referer
  end

  def create
    @hopper = Scale.find(params[:scale_id]).hoppers.new params[:hopper]
    if @hopper.save
      @hopper_lot = @hopper.hopper_lot.new params[:hopper_lot]
      @hopper_lot.save
      flash[:notice] = 'Tolva guardada con éxito'
      redirect_to session[:return_to]
    else
      fill_new
      render :new
    end
  end

  def update
    @hopper = Hopper.find params[:id]
    @hopper.update_attributes(params[:hopper])
    if @hopper.save
      @hopper_lot = @hopper.hopper_lot.new params[:hopper_lot]
      @hopper_lot.save
      flash[:notice] = 'Tolva actualizada con éxito'
      redirect_to session[:return_to]
    else
      fill_edit
      render :edit
    end
  end

  def set_as_main_hopper
    @hopper = Hopper.find params[:id]
    @hopper.set_as_main_hopper()
    redirect_to request.referer
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

  def fill_new
    @lots = Lot.find :all,
                     :include => :ingredient,
                     :conditions => {:active => true, :in_use => true}
    @scales = Scale.all
  end

  def fill_edit
    @lots = Lot.find :all,
                     :include => :ingredient,
                     :conditions => {:active => true, :in_use => true}
    @scales = Scale.all
    @hopper = Hopper.find params[:id]
    @current_lot = @hopper.current_lot
  end
end
