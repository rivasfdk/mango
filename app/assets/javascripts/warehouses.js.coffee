$ ->
  $('#ing').click (event) ->
    event.preventDefault()
    $('#ingredient_menu').toggle()
  
$ ->
  $('#prod').click (event) ->
    event.preventDefault()
    $('#product_menu').toggle()
