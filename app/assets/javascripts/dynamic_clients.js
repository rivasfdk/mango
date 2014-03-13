var clients = [];

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

$(function() {
  $('#client_type_client').change(clientTypeSelected);
  $('#client_type_factory').change(clientTypeSelected);
  $.getJSON( "/clients/all", function(data) {
    clients = data;
    clientTypeSelected();
  });
});
