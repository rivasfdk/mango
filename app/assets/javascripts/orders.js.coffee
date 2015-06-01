update_total = ->
  total = 0
  $("tbody").children().each ->
    if $(this).find('#ingredients__modify').val() == '1'
      total += parseFloat($(this).find('#ingredients__real').val())
    else
      total += parseFloat($(this).find('.current-real').html())
  $("#order-total").html(total)

enable_edit = ->
  row = $(this).parents('tr')
  row.find('.current-real').hide()
  row.find('.new-real').show()
  row.find('#ingredients__modify').val('1')
  $(this).hide()
  row.find('.action-cancel').show()

disable_edit = ->
  row = $(this).parents('tr')
  row.find('.current-real').show()
  row.find('.new-real').hide()
  row.find('#ingredients__modify').val('0')
  row.find('#ingredients__real').val(row.find('.current-real').html())
  $(this).hide()
  row.find('.action-modify').show()
  update_total()

$ ->
  $('.action-modify').click(enable_edit)
  $('.action-cancel').click(disable_edit)
  $('.new-real').on('change keyup', update_total)
