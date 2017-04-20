$ ->
  $("#warehouse_sacks").change warehouse_sack

warehouse_sack = ->
  if $("#warehouse_sacks").is(':checked')
    $("#warehousecontent").hide()
    $("#warehouse_lot_id").val(null)
    $("#warehouse_product_lot_id").val(null)
  else
    $("#warehousecontent").show()
    $("#warehouse_lot_id").val(1)
    $("#warehouse_product_lot_id").val(1)