
$(function() {
    $('#report_by_alarm_type_1').bind('change', type_changed_1);
    $('#report_by_alarm_type_2').bind('change', type_changed_2);
    $('#report_by_factory_1').bind('change', value_changed_1);
    $('#report_by_factory_2').bind('change', value_changed_2);
    $('#content_type_ingredient').bind('change', type_changed);
    $('#content_type_product').bind('change', type_changed);
});

function type_changed_1() {
    if ($('#report_by_alarm_type_1').is(':checked')) {
      $('#report_alarm_type_id_1_chosen').show();
    } else {
      $('#report_alarm_type_id_1_chosen').hide();
    }
}

function type_changed_2() {
    if ($('#report_by_alarm_type_2').is(':checked')) {
      $('#report_alarm_type_id_2_chosen').show();
    } else {
      $('#report_alarm_type_id_2_chosen').hide();
    }
}

function value_changed_1() {
    if ($('#report_by_factory_1').is(':checked')) {
      $('#report_factory_id_1_chosen').show();
    } else {
      $('#report_factory_id_1_chosen').hide();
    }
}

function value_changed_2() {
    if ($('#report_by_factory_2').is(':checked')) {
      $('#report_factory_id_2_chosen').show();
    } else {
      $('#report_factory_id_2_chosen').hide();
    }
}

function type_changed() {
    if ($('#content_type_ingredient').is(':checked')) {
      $('#lot').show();
      $('#product_lot').hide();
    } else {
      $('#lot').hide();
      $('#product_lot').show();
    }
}
