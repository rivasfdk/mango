$ ->
  $("#warehouse_sacks").change warehouse_sack

warehouse_sack = ->
  if $("#warehouse_sacks").is(':checked')
    $("#warehousecontent").hide()
  else
    $("#warehousecontent").show()