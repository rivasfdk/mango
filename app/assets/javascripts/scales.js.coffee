# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

not_weighed_changed = ->
  if $("#scale_not_weighed").is(':checked')
    $("#scale_weights").hide()
  else
    $("#scale_weights").show()

$ ->
  not_weighed_changed()
  $("#scale_not_weighed").change(not_weighed_changed)
