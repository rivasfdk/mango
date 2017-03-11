//= require jquery
//= require jquery_ujs
//= require jquery-ui/datepicker
//= require jquery-ui/datepicker-es
//= require chosen.jquery
//= require_tree .
//= stub dynamic_clients
//= stub jquery.flot.axislabels

var clients = [];
var lots = [];
var product_lots = [];
var chosen_params = {
  placeholder_text_multiple: "Seleccione algunas opciones",
  placeholder_text_single: "Seleccione una opción",
  no_results_text: "No hay resultados",
}

$(function(){
    $('.datepicker').datepicker({readonly: true});
    $('.chosen-select').chosen(chosen_params);
    $('#report_alarm_type_id_1_chosen').hide();
    $('#report_alarm_type_id_2_chosen').hide();
    $('#report_factory_id_1_chosen').hide();
    $('#report_factory_id_2_chosen').hide();
    $('#product_lot').hide();
    $('.report-details').hide();
    $("#order_recipe_id").change(update_product_lots);
    $("#order_client_id").change(update_product_lots);
    $("input[name=client_type]").change(update_product_lots);
    $('#client_type_client').trigger('change');
    $("#order_product_lot_id").change(update_product_lot_comment);
    $("#order_auto_product_lot").change(hideProductLots);
    $('#report_by_recipe').trigger('change');
    $('#report_by_recipe_2').trigger('change');
    $('#report_by_recipe_3').trigger('change');
    $('#report_by_recipe_4').trigger('change');
    $('#report_by_ingredients').trigger('change');
    $('#report_by_clients').trigger('change');
    $('#report_by_client').trigger('change');
    $('#report_by_client_2').trigger('change');
    $('#report_by_products').trigger('change');
    $('#report_by_products_2').trigger('change');
    $('#report_date_type_1').trigger('change');
    $('#report_time_unit_1').trigger('change');
    $('#report_by_ticket_type').trigger('change');
    $('#report_by_driver').trigger('change');
    $('#report_by_ticket_content').trigger('change');
    $('#report_by_factory_3').trigger('change');
    $('#report_by_client_4').trigger('change');
    $('#report_by_content').trigger('change');
    $('#report_content_type_1').trigger('change');
    $('#report_content_type_2').trigger('change');
    $('#report_ticket_by_content').trigger('change');
    $('#report_ticket_content_type_1').trigger('change');
    $('#report_ticket_content_type_2').trigger('change');
    $('#report_by_select_ingredients').trigger('change');
    $('#orden').trigger('change');
    $("#ticket_incoming_weight").val('######');
    $("#ticket_incoming_weight").prop('readOnly', true);
    $("#ticket_outgoing_weight").val('######');
    $("#ticket_outgoing_weight").prop('readOnly', true);
    hideProductLots();
});

function clientTypeSelected() {
  factory = $('#client_type_factory').is(':checked');
  select = $('#order_client_id');
  select.empty();
  select.append(new Option("", ""));
  $.each(clients, function(_, client) {
    if (client.factory == factory)
      select.append(new Option(client.name, client.id));
  });
  select.trigger("chosen:updated");
}

function submit_product_lot_parameter_list_edit_form() {
    $('#product_lot_parameter_list_edit_form').submit();
}
function submit_lot_parameter_list_edit_form() {
    $('#lot_parameter_list_edit_form').submit();
}
function submit_settings_edit_form() {
    $('#settings_edit_form').submit();
}

function submit_recipe_new_form() {
    $('#recipe_new_form').submit();
}

function submit_recipe_edit_form() {
    $('#recipe_edit_form').submit();
}

function submit_recipe_upload_form() {
    $('#recipe_upload_form').hide();
    $('#data_progress').show();
    $('#recipe_upload_form').submit();
}

function submit_medicament_recipe_new_form() {
    $('#medicament_recipe_new_form').submit();
}

function submit_medicament_recipe_edit_form() {
    $('#medicament_recipe_edit_form').submit();
}

function submit_ingredient_new_form() {
    $('#ingredient_new_form').submit();
}

function submit_ingredient_edit_form() {
    $('#ingredient_edit_form').submit();
}

function submit_user_new_form() {
    $('#user_new_form').submit();
}

function submit_user_edit_form() {
    $('#user_edit_form').submit();
}

function submit_hopper_new_form() {
    $('#hopper_new_form').submit();
}

function submit_hopper_edit_form() {
    $('#hopper_edit_form').submit();
}

function submit_hopper_change_form() {
    $('#hopper_change_form').submit();
}

function submit_hopper_fill_form() {
    $('#hopper_fill_form').submit();
}

function submit_hopper_adjust_form() {
    $('#hopper_adjust_form').submit();
}

function submit_hopper_change_factory_lots_form() {
    $('#hopper_change_factory_lots_form').submit();
}

function submit_product_new_form() {
    $('#product_new_form').submit();
}

function submit_product_edit_form() {
    $('#product_edit_form').submit();
}

function submit_order_new_form() {
    $('#order_new_form').submit();
}

function submit_order_edit_form() {
    $('#order_edit_form').submit();
}

function submit_order_repair_form() {
    $('#order_repair_form').submit();
}

function submit_order_notify_form() {
    $('#order_notify_form').submit();
}

function submit_client_new_form() {
    $('#client_new_form').submit();
}

function submit_client_edit_form() {
    $('#client_edit_form').submit();
}

function submit_order_stat_type_new_form() {
    $('#order_stat_type_new_form').submit();
}

function submit_order_stat_type_edit_form() {
    $('#order_stat_type_edit_form').submit();
}

function submit_factory_new_form() {
    $('#factory_new_form').submit();
}

function submit_factory_edit_form() {
    $('#factory_edit_form').submit();
}

function submit_batch_new_form() {
    $('#batch_new_form').submit();
}

function submit_batch_edit_form() {
    $('#batch_edit_form').submit();
}

function submit_lot_new_form() {
    $('#lot_new_form').submit();
}

function submit_lot_edit_form() {
    $('#lot_edit_form').submit();
}

function submit_lot_adjust_form() {
    $('#lot_adjust_form').submit();
}

function submit_schedule_new_form() {
    $('#schedule_new_form').submit();
}

function submit_schedule_edit_form() {
    $('#schedule_edit_form').submit();
}

function submit_transaction_type_new_form() {
    $('#transaction_type_new_form').submit();
}

function submit_transaction_type_edit_form() {
    $('#transaction_type_edit_form').submit();
}

function submit_product_lot_new_form() {
    $('#product_lot_new_form').submit();
}

function submit_product_lot_edit_form() {
    $('#product_lot_edit_form').submit();
}

function submit_product_lot_adjust_form() {
    $('#product_lot_adjust_form').submit();
}

function submit_transaction_new_form() {
    $('#transaction_new_form').submit();
}

function submit_transaction_edit_form() {
    $('#transaction_edit_form').submit();
}

function submit_permission_new_form() {
    $('#permission_new_form').submit();
}

function submit_permission_edit_form() {
    $('#permission_edit_form').submit();
}

function submit_role_new_form() {
    $('#role_new_form').submit();
}

function submit_role_edit_form() {
    $('#role_edit_form').submit();
}

function submit_driver_new_form() {
    $('#driver_new_form').submit();
}

function submit_driver_edit_form() {
    $('#driver_edit_form').submit();
}

function submit_carrier_new_form() {
    $('#carrier_new_form').submit();
}

function submit_carrier_edit_form() {
    $('#carrier_edit_form').submit();
}

function submit_truck_new_form() {
    $('#truck_new_form').submit();
}

function submit_truck_edit_form() {
    $('#truck_edit_form').submit();
}

function submit_ticket_new_form() {
    $('#ticket_new_form').submit();
}

function submit_ticket_items_form() {
    $('#ticket_items_form').submit();
}

function submit_ticket_entry_form() {
    $('#ticket_entry_form').submit();
}

function submit_ticket_edit_form() {
    $('#ticket_edit_form').submit();
}

function submit_ticket_close_form() {
    $('#ticket_close_form').submit();
}

function submit_ticket_repair_form() {
    $('#ticket_repair_form').submit();
}

function submit_alarm_type_new_form() {
    $('#alarm_type_new_form').submit();
}

function submit_alarm_type_edit_form() {
    $('#alarm_type_edit_form').submit();
}

function submit_parameter_type_new_form() {
    $('#parameter_type_new_form').submit();
}

function submit_parameter_type_edit_form() {
    $('#parameter_type_edit_form').submit();
}

function submit_lot_parameter_type_new_form() {
    $('#lot_parameter_type_new_form').submit();
}

function submit_lot_parameter_type_edit_form() {
    $('#lot_parameter_type_edit_form').submit();
}

function submit_product_lot_parameter_type_new_form() {
    $('#product_lot_parameter_type_new_form').submit();
}

function submit_product_lot_parameter_type_edit_form() {
    $('#product_lot_parameter_type_edit_form').submit();
}

function submit_scale_new_form() {
    $('#scale_new_form').submit();
}

function submit_scale_edit_form() {
    $('#scale_edit_form').submit();
}

function submit_warehouse_new_form() {
    $('#warehouse_new_form').submit();
}

function submit_warehouse_edit_form() {
    $('#warehouse_edit_form').submit();
}

function submit_warehouse_change_ingredient_form() {
    $('#warehouse_change_ingredient_form').submit();
}

function submit_warehouse_change_product_form() {
    $('#warehouse_change_product_form').submit();
}

function submit_warehouse_fill_form() {
    $('#warehouse_fill_form').submit();
}

function submit_warehouse_adjust_form() {
    $('#warehouse_adjust_form').submit();
}

function submit_warehouse_type_new_form() {
    $('#warehouse_type_new_form').submit();
}

function submit_warehouse_type_edit_form() {
    $('#warehouse_type_edit_form').submit();
}

function toggle_report_details(id) {
    $('.report-details').hide();
    $(id).toggle();
}

function close_error_dialog() {
    $('#modal').remove();
}
