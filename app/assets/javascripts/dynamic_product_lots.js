var product_lots = [];

function recipeSelected() {
    select = $('#order_product_lot_id');
    select.empty();
    $.each(product_lots, function(_, product_lot) {
      select.append(new Option(product_lot.to_collection_select, product_lot.id));
    });
    select.trigger("chosen:updated");
}

function hideProductLots() {
  if ($("#order_create_product_lot").is(":checked"))
    $("#order_product_lot_id_chosen").hide();
  else
    $("#order_product_lot_id_chosen").show();
}

function update_product_lots() {
  var params = {};
  params["recipe_id"] = $("#order_recipe_id").val();
  if ($("#client_type_factory").is(":checked")) {
    params["factory_id"] = $("#order_client_id").val();
  }
  $.getJSON(
    "/product_lots/by_recipe",
    params,
    function(data) {
      product_lots = data;
     recipeSelected();
    }
  );
}

$(function() {
  $("#order_recipe_id").chosen()
                       .change(update_product_lots);
  $("#order_client_id").chosen()
                       .change(update_product_lots);
  $("input[name=client_type]").change(update_product_lots);
  $("#order_create_product_lot").change(hideProductLots);
  hideProductLots();
});
