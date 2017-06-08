type_changed_1 = ->
  $('#report_alarm_type_id_1_chosen').toggle($('#report_by_alarm_type_1').is(':checked'))
  return

type_changed_2 = ->
  $('#report_alarm_type_id_2_chosen').toggle($('#report_by_alarm_type_2').is(':checked'))
  return

value_changed_1 = ->
  $('#report_factory_id_1_chosen').toggle($('#report_by_factory_1').is(':checked'))
  return

value_changed_2 = ->
  $('#report_factory_id_2_chosen').toggle($('#report_by_factory_2').is(':checked'))
  return

type_changed = ->
  lot_checked = $('#content_type_ingredient').is(':checked')
  $('#lot').toggle(lot_checked)
  $('#product_lot').toggle(not lot_checked)
  return

load_lots = (lots) ->
  select = $('#report_lot_code')
  select.empty()
  $.each lots, (_, lot) ->
    select.append new Option(lot.to_collection_select, lot.code)
    return
  select.trigger 'chosen:updated'
  return

lot_type_changed = ->
  url = (if $('#report_lot_type_1').is(':checked') then '/lots/get_all' else '/product_lots/get_all')
  $.getJSON url, (data) ->
    lots = data
    load_lots(lots)
    return
  return

by_recipe_changed = ->
  $('#report_recipe_codes_chosen').toggle($('#report_by_recipe').is(':checked'))
  return

by_recipe_2_changed = ->
  $('#recipe_form').toggle($('#report_by_recipe_2').is(':checked'))

by_recipe_3_changed = ->
  $('#recipe_form').toggle($('#report_by_recipe_3').is(':checked'))

by_recipe_4_changed = ->
  $('#recipe_form_2').toggle($('#report_by_recipe_4').is(':checked'))

by_ingredients_changed = ->
  $('#ingredients_form').toggle($('#report_by_ingredients').is(':checked'))

by_clients_changed = ->
  $('#clients_form').toggle($('#report_by_client').is(':checked'))

by_client_changed = ->
  $('#client_form').toggle($('#report_by_client').is(':checked'))

by_ticket_type_changed = ->
  $('#ticket_type_form').toggle($('#report_by_ticket_type').is(':checked'))

by_ticket_content_changed = ->
  $('#ticket_content_form').toggle($('#report_by_ticket_content').is(':checked'))

by_driver_changed = ->
  $('#driver_form').toggle($('#report_by_driver').is(':checked'))

by_factory_changed = ->
  $('#factory_form').toggle($('#report_by_factory_3').is(':checked'))

by_client_2_changed = ->
  $('#client_form_2').toggle($('#report_by_client_2').is(':checked'))

by_client_4_changed = ->
  $('#client_form_3').toggle($('#report_by_client_4').is(':checked'))

by_products_changed = ->
  $('#products_form').toggle($('#report_by_products').is(':checked'))

by_products_2_changed = ->
  $('#products_form_2').toggle($('#report_by_products_2').is(':checked'))

date_type_changed = ->
  by_month = $('#report_date_type_1').is(':checked')
  $('#by_month').toggle(by_month)
  $('#by_range').toggle(!by_month)

time_range_changed = ->
  weeks_checked = $('#report_time_unit_1').is(':checked')
  $('#weeks_form').toggle(weeks_checked)
  $('#by_range').toggle(not weeks_checked)

by_content_changed = ->
  checked = $('#report_by_content').is(':checked')
  $('#content_box').toggle(checked)

content_type_1_changed = ->
  $('#ingredients_box').toggle($('#report_content_type_1').is(':checked'))
  $('#products_box').toggle($('#report_content_type_2').is(':checked'))

ticket_by_content_changed = ->
  $('#ticket_content_box').toggle($('#report_ticket_by_content').is(':checked'))

ticket_by_address_changed = ->
  $('#addresses').toggle($('#report_by_address').is(':checked'))

ticket_content_type_1_changed = ->
  $('#ticket_ingredients_box').toggle($('#report_ticket_content_type_1').is(':checked'))
  $('#ticket_products_box').toggle($('#report_ticket_content_type_2').is(':checked'))

select_ingredients_changed = ->
  $('#report_ingredients_ids_2_chosen').toggle($('#report_by_select_ingredients').is(':checked'))

select_content_type = ->
  $("#stocka_content_form").toggle($('#report_by_type_content').is(':checked'))

select_by_content = ->
  $("#stocka_content_box").toggle($('#report_by_content2').is(':checked'))

select_content = ->
  $('#stocka_ingredients_box').toggle($('#report_content_type2_1').is(':checked'))
  $('#stocka_products_box').toggle($('#report_content_type2_2').is(':checked'))

$ ->
  $('#report_by_alarm_type_1').change type_changed_1
  $('#report_by_alarm_type_2').change type_changed_2
  $('#report_by_factory_1').change value_changed_1
  $('#report_by_factory_2').change value_changed_2
  $('#content_type_ingredient').change type_changed
  $('#content_type_product').change type_changed
  $('#report_lot_type_1').change lot_type_changed
  $('#report_lot_type_2').change lot_type_changed
  $('.ingredients-select').chosen($.extend(chosen_params, {max_selected_options: 25}))
  $('.multiple-select').chosen($.extend(chosen_params))
  $('#report_by_recipe').change by_recipe_changed
  $('#report_by_recipe_2').change by_recipe_2_changed
  $('#report_by_recipe_3').change by_recipe_3_changed
  $('#report_by_recipe_4').change by_recipe_4_changed
  $('#report_by_ingredients').change by_ingredients_changed
  $('#report_by_clients').change by_clients_changed
  $('#report_by_client').change by_client_changed
  $('#report_by_client_2').change by_client_2_changed
  $('#report_by_products').change by_products_changed
  $('#report_by_products_2').change by_products_2_changed
  $('#report_date_type_1').change date_type_changed
  $('#report_date_type_2').change date_type_changed
  $('#report_time_unit_1').change time_range_changed
  $('#report_time_unit_2').change time_range_changed
  $('#report_by_ticket_type').change by_ticket_type_changed
  $('#report_by_driver').change by_driver_changed
  $('#report_by_ticket_content').change by_ticket_content_changed
  $('#report_by_factory_3').change by_factory_changed
  $('#report_by_client_4').change by_client_4_changed
  $('#report_by_content').change by_content_changed
  $('#report_content_type_1').change content_type_1_changed
  $('#report_content_type_2').change content_type_1_changed
  $('#report_ticket_by_content').change ticket_by_content_changed
  $('#report_ticket_content_type_1').change ticket_content_type_1_changed
  $('#report_ticket_content_type_2').change ticket_content_type_1_changed
  $('#report_by_select_ingredients').change select_ingredients_changed
  $('#report_by_type_content').change select_content_type
  $('#report_by_content2').change select_by_content
  $('#report_content_type2_1').change select_content
  $('#report_content_type2_2').change select_content
  $('#report_by_address').change ticket_by_address_changed
  return
