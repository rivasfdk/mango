// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

document.observe("dom:loaded", function() {
    hide_all_report_details();
});

function submit_recipe_new_form() {
    $('recipe_new_form').submit();
}

function submit_recipe_edit_form() {
    $('recipe_edit_form').submit();
}

function submit_recipe_upload_form() {
    $('recipe_upload_form').hide();
    $('data_progress').show();
    $('recipe_upload_form').submit();
}

function submit_ingredient_new_form() {
    $('ingredient_new_form').submit();
}

function submit_ingredient_edit_form() {
    $('ingredient_edit_form').submit();
}

function submit_user_new_form() {
    $('user_new_form').submit();
}

function submit_user_edit_form() {
    $('user_edit_form').submit();
}

function submit_hopper_new_form() {
    $('hopper_new_form').submit();
}

function submit_hopper_edit_form() {
    $('hopper_edit_form').submit();
}

function submit_product_new_form() {
    $('product_new_form').submit();
}

function submit_product_edit_form() {
    $('product_edit_form').submit();
}

function submit_order_new_form() {
    $('order_new_form').submit();
}

function submit_order_edit_form() {
    $('order_edit_form').submit();
}

function submit_client_new_form() {
    $('client_new_form').submit();
}

function submit_client_edit_form() {
    $('client_edit_form').submit();
}

function toggle_report_details(id) {
    $(id).toggle();
}

function hide_all_report_details() {
    if($('recipes_report_details') != null)
        $('recipes_report_details').hide();
    if($('otro_report_details') != null)
        $('otro_report_details').hide();
}

