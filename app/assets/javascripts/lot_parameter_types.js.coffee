# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

is_string_changed = ->
  if $("#lot_parameter_type_is_string").is(':checked')
    $("#not_string").hide()
  else
    $("#not_string").show()

$ ->
  is_string_changed()
  $("#lot_parameter_type_is_string").change(is_string_changed)
