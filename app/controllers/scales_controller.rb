# encoding: UTF-8

include MangoModule

class ScalesController < ApplicationController
  def index
    @scales, @hoppers_below_minimum = Scale.get_all
    @hoppers_transactions_enabled = is_mango_feature_available("hoppers_transactions")
  end

  def show
    @scale = Scale.find params[:id]
    @hoppers = Hopper.find_actives params[:id]
    mango_features = get_mango_features()
    @hoppers_transactions_enabled = mango_features.include?("hoppers_transactions")
    @show_hopper_factory_lots = mango_features.include?("factories")
  end

  def create
    @scale = Scale.new params[:scale]
    if @scale.save
      flash[:notice] = 'Balanza guardada con éxito'
      redirect_to :scales
    else
      render :new
    end
  end

  def edit
    @scale = Scale.find params[:id]
  end

  def update
    @scale = Scale.find params[:id]
    @scale.update_attributes(params[:scale])
    if @scale.save
      flash[:notice] = 'Balanza actualizada con éxito'
      redirect_to :scales
    else
      render :edit
    end
  end

  def destroy
    @scale = Scale.find params[:id]
    @scale.eliminate
    if @scale.errors.size.zero?
      flash[:notice] = "Balanza eliminada con éxito"
    else
      logger.error("Error eliminando balanza: #{@scale.errors.inspect}")
      flash[:type] = 'error'
      if not @scale.errors[:foreign_key].nil?
        flash[:notice] = 'La balanza no se puede eliminar porque tiene tolvas asociadas'
      elsif not @scale.errors[:unknown].nil?
        flash[:notice] = @scale.errors[:unknown]
      else
        flash[:notice] = "La balanza no se ha podido eliminar"
      end
    end
    redirect_to :scales
  end
end
