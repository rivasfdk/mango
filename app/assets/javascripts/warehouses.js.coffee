load_contents = (contents) ->
  select = $('#content_id')
  select.empty()
  $.each contents, (_, content) ->
    select.append new Option(content.to_collection_select, content.id)
    return
  select.trigger 'chosen:updated'
  return

content_type_changed = ->
  ingredient_checked = $('#warehouse_content_type_1').is(':checked')
  url = (if ingredient_checked then '/ingredients/get_all' else '/products/get_all')
  $.getJSON url, (data) ->
    contents = data
    load_contents(contents)
    return
  return

$ ->
  $("#warehouse_content_type_1").change content_type_changed
  $("#warehouse_content_type_2").change content_type_changed