class SettingsController < ApplicationController
  def edit
    @settings = Settings.first
  end

  def update
    @settings = Settings.first
    @settings.update_attributes(params[:settings])
    if @settings.save
      flash[:notice] = 'Configuración actualizada con éxito'
      render :edit
    else
      render :edit
    end
  end
end
