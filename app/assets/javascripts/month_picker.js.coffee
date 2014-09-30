$ ->
  update = ->
    year = $("#ui-datepicker-div .ui-datepicker-year :selected").val()
    month = $("#ui-datepicker-div .ui-datepicker-month :selected").val()
    $(this).datepicker('setDate', new Date(year, month, 1))
    $(this).datepicker('hide')

  month_pickers = $('.monthpicker')
  month_pickers.datepicker({
    readonly: true,
    changeMonth: true,
    changeYear: true,
    onChangeMonthYear: update
  })
  month_pickers.focus ->
    $(".ui-datepicker-calendar").hide();
    $("#ui-datepicker-div").position {
      my: "center top",
      at: "center bottom",
      of: $(this)
    }
  return
