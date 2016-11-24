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


