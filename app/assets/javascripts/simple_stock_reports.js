document.observe("dom:loaded", function() {
    $('report_factory_id_1_chzn').hide();
    $('report_factory_id_2_chzn').hide();
    $('report_by_factory_1').observe('change', value_changed_1);
    $('report_by_factory_2').observe('change', value_changed_2);
});

function value_changed_1() {
    if ($('report_by_factory_1').checked) {
      $('report_factory_id_1_chzn').show();
    } else {
      $('report_factory_id_1_chzn').hide()
    }
}

function value_changed_2() {
    if ($('report_by_factory_2').checked) {
      $('report_factory_id_2_chzn').show();
    } else {
      $('report_factory_id_2_chzn').hide()
    }
}
