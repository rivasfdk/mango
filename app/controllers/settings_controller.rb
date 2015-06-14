include MangoModule

class SettingsController < ApplicationController
  skip_before_filter :check_permissions, only: [:show, :features]
  def show
    @settings = Settings.first
    render json: @settings
  end

  def features
    @features = get_mango_features()
    render json: @features
  end

  def edit
    @settings = Settings.first
    @mango_features = get_mango_features()
    @hoppers_transactions_enabled = @mango_features.include?("hoppers_transactions")
    @romano_enabled = @mango_features.include?("romano")
  end

  def update
    edit
    @settings.update_attributes(params[:settings])
    if @settings.save
      flash[:notice] = 'Configuración actualizada con éxito'
      render :edit
    else
      render :edit
    end
  end
end
