$(function() {
  $('#report_by_alarm_type_1').change(type_changed_1);
  $('#report_by_alarm_type_2').change(type_changed_2);
  $('#report_by_factory_1').change(value_changed_1);
  $('#report_by_factory_2').change(value_changed_2);
  $('#content_type_ingredient').change(type_changed);
  $('#content_type_product').change(type_changed);
  $("#report_lot_type_1").change(lot_type_changed);
  $("#report_lot_type_2").change(lot_type_changed);
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

function load_lots() {
  select = $("#report_lot_code");
  select.empty();
  $.each(lots, function(_, lot) {
    select.append(new Option(lot.to_collection_select, lot.code));
  });
  select.trigger("chosen:updated");
}

function lot_type_changed() {
  var url = $("#report_lot_type_1").is(":checked") ? "/lots/get_all" : "/product_lots/get_all";
  $.getJSON(
    url,
    function(data) {
      lots = data;
      load_lots();
    }
  );
}
