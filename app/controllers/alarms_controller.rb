# encoding: UTF-8
#
class AlarmsController < ApplicationController
  def create
    render xml: Alarm.create_from_scada(params[:alarm])
  end
end
