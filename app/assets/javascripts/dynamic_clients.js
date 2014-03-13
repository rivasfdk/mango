$(function() {
  $('#client_type_client').change(clientTypeSelected);
  $('#client_type_factory').change(clientTypeSelected);
  $.getJSON( "/clients/all", function(data) {
    clients = data;
    clientTypeSelected();
  });
});
