window.remove_fields = (link) ->
  $(link).prev("input[type=hidden]").val "1"
  $(link).closest("tr").hide()
window.add_fields = (link, association, content) ->
  new_id = new Date().getTime()
  regexp = new RegExp("new_" + association, "g")
  $("#tabledata tbody").append content.replace(regexp, new_id)
  row_count = $("#tabledata tbody tr").size()
  last_row = $("#tabledata tbody tr").last()
  last_row.addClass (if row_count % 2 is 0 then "alternate" else "blank")
  $(".chosen-select").chosen chosen_params
  $(".content_type_checkbox").change update_transaction_lots
  sack_checkbox = $(".sack_checkbox")
  sack_checkbox.change show_sack_fields
  sack_checkbox.trigger "change"
  $(".sacks_field").change update_sack_total
  $(".sack_weight_field").change update_sack_total

update_transaction_lots = ->
  lot_selected = $(this).val() is '1'
  path = (if lot_selected then "/lots/get_all" else "/product_lots/get_all")
  select = $(this).parent().children("select")
  $.getJSON path, (data) ->
    lots = data
    select.empty()
    $.each lots, (_, lot) ->
      select.append new Option(lot.to_collection_select, lot.id)
    select.trigger "chosen:updated"

show_sack_fields = ->
  sack_selected = $(this).is(":checked")
  row = $(this).parents("tr")
  sacks_field = row.find(".sacks_field")
  sack_weight_field = row.find(".sack_weight_field")
  amount_field = row.find(".amount_field")
  sacks_field.toggle sack_selected
  sack_weight_field.toggle sack_selected
  amount_field.attr "readonly", sack_selected
  if sack_selected
    if sacks_field.val() is ""
      sacks_field.val 0
      sack_weight_field.val 0
    calculate_sack_total sacks_field, sack_weight_field, amount_field
calculate_sack_total = (sacks, sack_weight, amount) ->
  amount.val parseFloat(sacks.val()) * parseFloat(sack_weight.val())
update_sack_total = ->
  row = $(this).parents("tr")
  sacks_field = row.find(".sacks_field")
  sack_weight_field = row.find(".sack_weight_field")
  amount_field = row.find(".amount_field")
  calculate_sack_total sacks_field, sack_weight_field, amount_field
$ ->
  sack_checkboxes = $(".sack_checkbox")
  sack_checkboxes.change show_sack_fields
  sack_checkboxes.trigger "change"
  $(".sacks_field").change update_sack_total
  $(".sack_weight_field").change update_sack_total

load_contents = (contents) ->
  select = $('#content_id, #report_content_id')
  select.empty()
  $.each contents, (_, content) ->
    select.append new Option(content.to_collection_select, content.id)
    return
  select.trigger 'chosen:updated'
  return

content_type_changed = ->
  ingredient_checked = $('#ticket_content_type_1, #report_ticket_content_type_1').is(':checked')
  url = (if ingredient_checked then '/ingredients/get_all' else '/products/get_all')
  $.getJSON url, (data) ->
    contents = data
    load_contents(contents)
    return
  return

$ ->
  $("#ticket_content_type_1, #report_ticket_content_type_1").change content_type_changed
  $("#ticket_content_type_2, #report_ticket_content_type_2").change content_type_changed


ticket_type_changed = ->
  url = (if $("#ticket_ticket_type_id_1").is(':checked') then '/ticket_orders/get_all_reception' else '/ticket_orders/get_all_dispatch')
  $("#order_type").html((if $("#ticket_ticket_type_id_1").is(':checked') then 'Orden de compra' else 'Orden de salida'))
  select = $("#ticket_id_order")
  $.getJSON url, (data) ->
    orders = data
    select.empty()
    select.append new Option("")
    $.each orders, (_, order) ->
      select.append new Option(order.to_collection_select, order.id)
    select.trigger "chosen:updated"

$ ->
  $("#ticket_ticket_type_id_1").change ticket_type_changed
  $("#ticket_ticket_type_id_2").change ticket_type_changed

id_order_changed = ->
  url = '/ticket_orders/get_order_data'
  client_order = $("#ticket_client_id")
  params = {}
  params["id_order"] = $("#ticket_id_order").val()
  $.getJSON url, params, (data) ->
    client = data
    console.log client.name
    console.log client.address
    client_order.empty()
    client_order.append new Option(client.name,client.id)
    client_order.trigger "chosen:updated"
    $("#ticket_address").val(client.address)

$ ->
  $("#id_order").change id_order_changed

captura = true

update_weight = ->
  if captura and self.location.href.includes('/tickets/new')
    socket = new WebSocket('ws://192.168.1.106:2000')
    socket.onopen = ()->
      console.log "conected!"
    socket.onmessage = (msg)->
      $("#ticket_incoming_weight").val(msg.data)

$ ->
  setInterval(update_weight, 1000)

capture_weight = ->
  if captura
    captura = false
  else
    captura = true

$ ->
  $("#boton_capturar").click capture_weight

