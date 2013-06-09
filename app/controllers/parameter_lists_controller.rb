# encoding: UTF-8

class ParameterListsController < ApplicationController
  def clone
    original_parameter_list = ParameterList.find params[:id]
    new_parameter_list = original_parameter_list.clone
    original_parameter_list.active = false
    original_parameter_list.save
    new_parameter_list.save

    original_parameter_list.parameters.each do |p|
      new_p = p.clone
      new_p.parameter_list_id = new_parameter_list.id
      new_p.save
    end
    redirect_to request.referer + "#parameters"
  end
end
