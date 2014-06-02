find_orientation = ->
  if window.innerWidth < window.innerHeight
    "portrait"
  else if window.innerWidth > window.innerHeight
    "landscape"
  else
    "square"

set_viewport = ->
  if window.innerWidth <= 767 && find_orientation() == "landscape"
    document.getElementById("viewport").setAttribute("content", "width=960, initial-scale=1.0");
  else if window.innerWidth <=767
    document.getElementById("viewport").setAttribute("content", "width=device-width, initial-scale=1.0");

$(window).on "rotate, resize", ->
  set_viewport()

$(document).ready ->
  set_viewport()
