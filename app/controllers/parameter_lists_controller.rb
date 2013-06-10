# encoding: UTF-8

class ParameterListsController < ApplicationController
  def clone
    original_parameter_list = ParameterList.find params[:id]
    new_parameter_list = original_parameter_list.dup
    original_parameter_list.active = false
    original_parameter_list.save
    new_parameter_list.save

    new_parameter_list.parameters.each do |p|
      p.value = original_parameter_list.parameters.where(:parameter_type_id => p.parameter_type_id).first.value
      p.save
    end

    redirect_to request.referer + "#parameters"
  end
end
