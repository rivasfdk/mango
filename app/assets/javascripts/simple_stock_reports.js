document.observe("dom:loaded", function() {
    $('report_factory_id_chzn').hide();
    $('report_by_factory').observe('change', value_changed);
});

function value_changed() {
    if ($('report_by_factory').checked) {
      $('report_factory_id_chzn').show();
    } else {
      $('report_factory_id_chzn').hide()
    }
}