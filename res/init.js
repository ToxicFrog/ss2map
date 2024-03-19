var search_results = []
var maps = []
var map

for (k in levels) maps[k] = true
if (window.location.hash != "") {
  var hash = window.location.hash.substr(1).split(",")[0]
  var first = parseInt(hash)
  DEFAULT = isNaN(first) ? DEFAULT : first
}

/* Load the map data for the selected levels. */
for (var i=0; i < maps.length; ++i) {
  if (!maps[i]) { continue }
  var script = document.createElement("script")
  script.type = "text/javascript"
  script.src = "./" + i + ".js"
  document.getElementsByTagName("head")[0].appendChild(script)
}

// Wait for all the other scripts and DOM to load, then initialize the UI
// and load the default map.
window.addEventListener('load', function() {
  // Hide the level select entries for levels we didn't load.
  var options = document.getElementById("levelselect").getElementsByTagName("option")
  for (var i=options.length-1; i >= 0; --i) {
    if (!maps[options[i].value]) {
      options[i].parentNode.removeChild(options[i])
    }
  }

  initCategories()

  map = { index: -1 }
  showMap(DEFAULT)

  installPanZoomHandlers(document.getElementById('mapcell'));
}, false)

// Setup event handlers for pan/zoom on the div containing the canvas.
// We expect `map` to hold the currently viewed map, with fields `scale`
// and `pan.x/y`.
function installPanZoomHandlers(container) {
  var dragging = false;
  var dragstate = {};

  container.addEventListener('mousedown', function(evt) {
    if (evt.which != 1) return false;
    dragging = true;
    dragstate = {
      startX: evt.pageX, startY: evt.pageY,
      panX: map.pan.x, panY: map.pan.y,
    }
  });

  container.addEventListener('mousemove', function(evt) {
    if (!dragging) return false;
    map.dragging = true;
    map.pan.x = dragstate.panX - (evt.pageX - dragstate.startX)
    map.pan.y = dragstate.panY - (evt.pageY - dragstate.startY)
    applyPanAndZoom(map);
  });

  container.addEventListener('mouseup', function(evt) {
    dragging = false;
    map.dragging = false;
    dragstate = {};
  })

  container.addEventListener('wheel', function(evt) {
    tweakScale(evt.wheelDelta * 0.0004);
    evt.preventDefault();
  }, false);
}
