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
}