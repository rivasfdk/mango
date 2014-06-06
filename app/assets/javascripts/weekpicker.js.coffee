displayWeeks = ->
  window.setTimeout( ->
      # Hovered week
      weeks = $('#ui-datepicker-div tr')
      weeks.bind('mousemove', -> $(this).find('td a').addClass('ui-state-hover'))
      weeks.bind('mouseleave', -> $(this).find('td a').removeClass('ui-state-hover'))
      # Selected week
      selectedWeek = $('#ui-datepicker-div tbody').find('a.ui-state-active').closest('tr')
      selectedWeek.find('td a').addClass('ui-state-active')
      return
    , 1)

getFirstDayOfTheWeek = ->
  date = $(this).datepicker('getDate')
  if date
    day = date.getDay()
    daysFromMonday = if day == 0 then 6 else day - 1
    date.setDate(date.getDate() - daysFromMonday)
    $(this).datepicker('setDate', date)
    $(this).blur()
  return

$ ->
  $('.weekpicker').datepicker({
    readonly: true
    showOtherMonths: true
    selectOtherMonths: true
    beforeShow: displayWeeks
    onChangeMonthYear: displayWeeks
    onSelect: getFirstDayOfTheWeek
  })
  return