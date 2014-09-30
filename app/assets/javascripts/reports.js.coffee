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

by_ingredients_changed = ->
  $('#ingredients_form').toggle($('#report_by_ingredients').is(':checked'))

time_range_changed = ->
  weeks_checked = $('#report_time_unit_1').is(':checked')
  $('#weeks_form').toggle(weeks_checked)
  $('#months_form').toggle(not weeks_checked)

$ ->
  $('#report_by_alarm_type_1').change type_changed_1
  $('#report_by_alarm_type_2').change type_changed_2
  $('#report_by_factory_1').change value_changed_1
  $('#report_by_factory_2').change value_changed_2
  $('#content_type_ingredient').change type_changed
  $('#content_type_product').change type_changed
  $('#report_lot_type_1').change lot_type_changed
  $('#report_lot_type_2').change lot_type_changed
  $('.ingredients-select').chosen($.extend(chosen_params, {max_selected_options: 12}))
  $('#report_by_recipe').change by_recipe_changed
  $('#report_by_recipe_2').change by_recipe_2_changed
  $('#report_by_ingredients').change by_ingredients_changed
  $('#report_time_unit_1').change time_range_changed
  $('#report_time_unit_2').change time_range_changed
  return
