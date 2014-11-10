$(function() {
  sack_checkboxes = $('.sack_checkbox');
  sack_checkboxes.change(show_sack_fields);
  sack_checkboxes.trigger('change');
  $('.sacks_field').change(update_sack_total);
  $('.sack_weight_field').change(update_sack_total);
})

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest("tr").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $("#tabledata tbody").append(content.replace(regexp, new_id));
  var row_count =  $("#tabledata tbody tr").size()
  var last_row = $("#tabledata tbody tr").last();
  last_row.addClass(row_count % 2 == 0 ? "alternate" : "blank");
  $('.chosen-select').chosen(chosen_params);
  $('.content_type_checkbox').change(update_transaction_lots);
  $('.sack_checkbox').change(show_sack_fields);
}

function update_transaction_lots() {
  var lot_selected = $(this).val() == 1;
  var path = lot_selected ? '/lots/get_all' : '/product_lots/get_all';
  var select = $(this).parent().children('select');
  $.getJSON(
    path,
    function(data) {
      var lots = data;
      select.empty();
      $.each(lots, function(_, lot) {
        select.append(new Option(lot.to_collection_select, lot.id));
      });
      select.trigger('chosen:updated');
    }
  );
}

function show_sack_fields() {
  var sack_selected = $(this).is(':checked');
  var row = $(this).parents('tr');
  var sacks_field = row.find('.sacks_field');
  var sack_weight_field = row.find('.sack_weight_field');
  var amount_field = row.find('.amount_field');
  sacks_field.toggle(sack_selected);
  sack_weight_field.toggle(sack_selected);
  amount_field.attr('readonly', sack_selected);
  if (sack_selected) {
  	sacks_field.val(0);
  	sack_weight_field.val(0);
    calculate_sack_total(sacks_field, sack_weight_field, amount_field);
  }
}

function calculate_sack_total(sacks, sack_weight, amount) {
  amount.val(parseFloat(sacks.val()) * parseFloat(sack_weight.val()));
}

function update_sack_total() {
  var row = $(this).parents('tr');
  var sacks_field = row.find('.sacks_field');
  var sack_weight_field = row.find('.sack_weight_field');
  var amount_field = row.find('.amount_field');
  calculate_sack_total(sacks_field, sack_weight_field, amount_field);
}