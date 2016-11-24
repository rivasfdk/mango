function select_ticket_type(){
  var order = $("#orden").is(':checked');
  if (order) {
    var ticket_type = $("#ticket_ticket_type_id_1").is(':checked');
    if (ticket_type) {
      $("#purord").show();
      $("#salord").hide();
    }else{
      $("#purord").hide();
      $("#salord").show();
    };
  }
};

function hide_orders(){
  var order = $("#orden").is(':checked');
  if (order) {
    select_ticket_type();
  }else{
    $("#purord").hide();
    $("#salord").hide();
  };
}

$(document).ready(function(){
  $("#ticket_ticket_type_id_1").change(function(){
    select_ticket_type();
  });
  $("#ticket_ticket_type_id_2").change(function(){
    select_ticket_type();
  });
  $("#orden").change(function(){
    hide_orders();
  });
});
