document.observe("dom:loaded", function() {
    $('report_alarm_type_id_1_chzn').hide();
    $('report_alarm_type_id_2_chzn').hide();
    $('report_by_alarm_type_1').observe('change', type_changed_1);
    $('report_by_alarm_type_2').observe('change', type_changed_2);
});

function type_changed_1() {
    if ($('report_by_alarm_type_1').checked) {
      $('report_alarm_type_id_1_chzn').show();
    } else {
      $('report_alarm_type_id_1_chzn').hide()
    }
}

function type_changed_2() {
    if ($('report_by_alarm_type_2').checked) {
      $('report_alarm_type_id_2_chzn').show();
    } else {
      $('report_alarm_type_id_2_chzn').hide()
    }
}
