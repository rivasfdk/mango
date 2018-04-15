window.remove_fields = (link) ->
  $(link).prev("input[type=hidden]").val "1"
  $(link).closest("tr").hide()

content_type = 1

window.add_fields = (link, association, content) ->
  content_type = 1
  new_id = new Date().getTime()
  regexp = new RegExp("new_" + association, "g")
  $("#tabledata tbody").append content.replace(regexp, new_id)
  row_count = $("#tabledata tbody tr").size()
  last_row = $("#tabledata tbody tr").last()
  last_row.addClass (if row_count % 2 is 0 then "alternate" else "blank")
  $(".chosen-select").chosen chosen_params
  $(".content_type_checkbox").change update_transaction_lots
  $(".chosen-select").change update_transaction_warehouse
  sack_checkbox = $(".sack_checkbox")
  sack_checkbox.change show_sack_fields
  sack_checkbox.trigger "change"
  $(".sacks_field").change update_sack_total
  $(".sack_weight_field").change update_sack_total

update_transaction_lots = ->
  lot_selected = $(this).val() is '1'
  path = (if lot_selected then "/lots/get_all" else "/product_lots/get_all")
  content_type = (if lot_selected then 1 else 0)
  objlot = $(this).parent().children("select")[0].id
  select = $("#"+"#{objlot}")
  $.getJSON path, (data) ->
    lots = data
    select.empty()
    select.append new Option("")
    $.each lots, (_, lot) ->
      select.append new Option(lot.to_collection_select, lot.id)
    select.trigger "chosen:updated"

update_transaction_warehouse = ->
  params = {}
  objlot = $(this)[0].id
  params["lot_id"] = $("#"+"#{objlot}").val()
  params["content_type"] = content_type
  url = '/ticket_orders/get_item_warehouse'
  objwh = $(this).parent().children("select")[1].id
  warehouse = $("#"+"#{objwh}")
  $.getJSON url, params, (data) ->
    wh = data
    warehouse.empty()
    $.each wh, (_, w) ->
      warehouse.append new Option(w.to_collection_select, w.id)
    warehouse.trigger "chosen:updated"
    console.log wh

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
  $("#onlyreception").toggle($("#ticket_ticket_type_id_1").is(':checked'))

$ ->
  $("#ticket_ticket_type_id_1").change ticket_type_changed
  $("#ticket_ticket_type_id_2").change ticket_type_changed

id_order_changed = ->
  url = '/ticket_orders/get_order_client'
  client_order = $("#ticket_client_id")
  params = {}
  params["id_order"] = $("#ticket_id_order").val()
  $.getJSON url, params, (data) ->
    client = data
    client_order.empty()
    client_order.append new Option(client.name,client.id)
    client_order.trigger "chosen:updated"
    $("#ticket_address").val(client.address)
  url = '/ticket_orders/get_item_warehouse'
  warehouse = $("#ticket_warehouse_id")
  $.getJSON url, params, (data) ->
    wh = data
    warehouse.empty()
    $.each wh, (_, w) ->
      warehouse.append new Option(w.to_collection_select, w.id)
    warehouse.trigger "chosen:updated"


$ ->
  $("#id_order").change id_order_changed

id_client_changed = ->
  url = '/clients/get_client'
  params = {}
  params["id_client"] = $("#ticket_client_id").val()
  $.getJSON url, params, (data) ->
    client = data
    $("#ticket_address").val(client.address)

$ ->
  $("#id_client").change id_client_changed

#create ticket new driver

check_driver_validation = ->
  if $("#drivername").val().length > 3 and $("#driverci").val().length > 3
    $("#create_driver").attr("disabled", false)
  else
    $("#create_driver").attr("disabled", true)

$ ->
  $("#new_driver").click show_new_driver_form

show_new_driver_form = ->
  $("#drivername").val("")
  $("#driverci").val("")
  $("#new_driver_form").show()
  check_driver_validation()

$ ->
  $("#cancel_driver").click hide_new_driver_form

hide_new_driver_form = ->
  $("#new_driver_form").hide()


$ ->
  $("#drivername").focus(check_driver_validation).keyup(check_driver_validation)
  $("#driverci").focus(check_driver_validation).keyup(check_driver_validation)

create_new_driver = ->
  $.ajax '/drivers',
    type: 'POST'
    dataType: 'json'
    data: { driver: {name: $("#drivername").val(), ci: $("#driverci").val(), frequent: $("#frequent_driver").is(':checked') }}
    error: (jqXHR, textStatus, errorThrown) ->
      alert "ERROR EN LOS DATOS, VERIFIQUE"
    success: (data, textStatus, jqXHR) ->
      console.log data
      driver = data.driver
      driver_select = $("#ticket_driver_id")
      driver_select.empty()
      format = driver.ci+" - "+driver.name
      driver_select.append new Option(format,driver.id)
      driver_select.trigger "chosen:updated"
    $("#new_driver_form").hide()

$ ->
  $("#create_driver").click create_new_driver

#create ticket new truck

check_truck_validation = ->
  if $("#truckplate").val().length > 3 and $("#carrier_id").val().length > 0
    $("#create_truck").attr("disabled", false)
  else
    $("#create_truck").attr("disabled", true)

$ ->
  $("#new_truck").click show_new_truck_form

show_new_truck_form = ->
  $("#truckplate").val("")
  $("#new_truck_form").show()
  check_truck_validation()

$ ->
  $("#cancel_truck").click hide_new_truck_form

hide_new_truck_form = ->
  $("#new_truck_form").hide()

$ ->
  $("#truckplate").focus(check_truck_validation).keyup(check_truck_validation)
  $("#create_truck").mouseover(check_truck_validation)

create_new_truck = ->
  $.ajax '/trucks',
    type: 'POST'
    dataType: 'json'
    data: { truck: {carrier_id: $("#carrier_id").val(), license_plate: $("#truckplate").val(), frequent: $("#frequent_truck").is(':checked') }}
    error: (jqXHR, textStatus, errorThrown) ->
      alert "ERROR EN LOS DATOS, VERIFIQUE"
    success: (data, textStatus, jqXHR) ->
      console.log data.truck
      truck = data.truck
      truck_select = $("#ticket_truck_id")
      truck_select.empty()
      format = truck.license_plate+" - "+truck.carrier.name
      truck_select.append new Option(format,truck.id)
      truck_select.trigger "chosen:updated"
    $("#new_truck_form").hide()
    

$ ->
  $("#create_truck").click create_new_truck

# show and capture weight

captura = true

server_romano_ip = ""

$ ->
  url = '/tickets/get_server_romano_ip'
  params = {}
  if (self.location.href.includes('/tickets') and self.location.href.includes('/entry'))
    params['type'] = 1
    $.getJSON url, params, (data) ->
      server_romano_ip = data[0]
      console.log server_romano_ip
  if (self.location.href.includes('/tickets') and self.location.href.includes('/close'))
    params['type'] = 2
    $.getJSON url, params, (data) ->
      server_romano_ip = data[0]
      console.log server_romano_ip

update_weight = ->
  if self.location.href.includes('/entry')
    not_manual = not $("#ticket_manual_incoming").is(':checked')
  else
    not_manual = not $("#ticket_manual_outgoing").is(':checked')
  if captura and not_manual
    socket = new WebSocket(server_romano_ip)
    socket.onopen = ()->
      console.log "conected!"
    socket.onmessage = (msg)->
      if self.location.href.includes('/entry')
        $("#ticket_incoming_weight").val(msg.data)
        console.log $("#ticket_incoming_weight").val()
      else
        $("#ticket_outgoing_weight").val(msg.data)
        console.log $("#ticket_outgoing_weight").val()

$ ->
  if (self.location.href.includes('/tickets') and self.location.href.includes('/entry')) or (self.location.href.includes('/tickets') and self.location.href.includes('/close'))
    setInterval(update_weight, 1000)

capture_weight = ->
  if captura
    captura = false
  else
    captura = true
  $("#boton_capturar").toggleClass('capture_button')

$ ->
  $("#boton_capturar").click capture_weight

manual_incoming = ->
  if $("#ticket_manual_incoming").is(':checked')
    $("#ticket_incoming_weight").prop('readOnly', false)
  else
    $("#ticket_incoming_weight").prop('readOnly', true)

$ ->
  $("#ticket_manual_incoming").change manual_incoming

manual_outgoing = ->
  if $("#ticket_manual_outgoing").is(':checked')
    $("#ticket_outgoing_weight").prop('readOnly', false)
  else
    $("#ticket_outgoing_weight").prop('readOnly', true)

$ ->
  $("#ticket_manual_outgoing").change manual_outgoing




