document.observe("dom:loaded", function() {
    $('product_lot').hide();
    $('content_type_ingredient').observe('change', type_changed);
    $('content_type_product').observe('change', type_changed);
});

function type_changed() {
    if ($('content_type_ingredient').checked) {
      $('lot').show();
      $('product_lot').hide();
    } else {
      $('lot').hide();
      $('product_lot').show();
    }
}
