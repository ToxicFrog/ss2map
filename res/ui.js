// General HTML manipulating/UI related functions //

function clearChildren(node) {
  while (node.firstChild) {
    node.removeChild(node.firstChild);
  }
}

var messageLocked = false
function writeMessage(node) {
  if (!messageLocked) {
    info = document.getElementById("info")
    clearChildren(info)
    info.appendChild(node)
  }
}
function lockMessage(lock) {
  messageLocked = lock
}
function clearMessage() {
  info = document.getElementById("info")
  clearChildren(info)
}

function infoToTable(info) {
  var buf = document.createElement("table");
  var props = info._props

  for (var i in props) {
    var tr = buf.appendChild(document.createElement("tr"));
    var th = tr.appendChild(document.createElement("th"));
    th.appendChild(document.createTextNode(props[i]));
    var td = tr.appendChild(document.createElement("td"));
    var value = info[props[i]]
    if (value instanceof Array) {
      for (var i in value) {
        td.appendChild(document.createTextNode(value[i]))
        td.appendChild(document.createElement("br"))
      }
    } else {
      td.appendChild(document.createTextNode(value));
    }
  }
  return buf;
}

function tileInfo(x, y) {
  return "[terrain info not implemented]"
  return infoToTable(map.tile_info[x + "," + y])
}

function objectInfo(id) {
  return infoToTable(map.object_info[id]);
}

function changeLevel() {
  showMap(document.getElementById("levelselect").value)
}

function showMap(i) {
  if (maps[i] && i != map.index) {
    clearChildren(document.getElementById('map'))
    destroyMap()
    map = maps[i]
    initMap()
    document.getElementById('map').appendChild(map.stage.content)
    // updateLayers()
    document.title = map.title + " - System Shock 2 Map"
    document.getElementById("levelselect").value = i
  }
}

function loadBackground(map) {
  if (map.bg) return;
  map.bgimage = new Image();
  map.bgimage.onload = function() {
    let terrain = new Kinetic.Image({
      x: map.bbox.x, y: map.bbox.y,
      image: map.bgimage,
      width: map.bbox.w,
      height: map.bbox.h,
    })
    map.mapLayer.add(terrain);
    map.mapLayer.draw();
  }
  map.bgimage.src = map.index+'.png';
}

function initMap() {
  if (map.stage)
    return;

  var container = document.getElementById('mapcell');
  console.log(container);
  console.log(container.getBoundingClientRect());
  map.stage = new Kinetic.Stage({
    container: 'map',
    width: container.getBoundingClientRect().width,
    height: container.getBoundingClientRect().height
  })

  let layersize = { x: -map.bbox.x, y: -map.bbox.y, width: map.bbox.w, height: map.bbox.h }
  map.mapLayer = new Kinetic.Layer(layersize); // level geometry
  map.searchLayer = new Kinetic.Layer(layersize) // search result hilighting

  loadBackground(map);

  map.objLayers = [] // objects, by object class
  for (var i = 0; i < 15 ; ++i) {
    map.objLayers[i] = new Kinetic.Layer(layersize);
  }

  map.drawTerrain()
  drawSearchResults()

  // map.searchLayer.hitGraphEnabled(true);
  // map.searchLayer.on('mousedown', function() { lockMessage(false); clearMessage(); })
  map.mapLayer.hitGraphEnabled(true);
  map.mapLayer.on('click', function() { if (map.dragging) return; lockMessage(false); clearMessage(); })

  map.stage.add(map.mapLayer);
  for (var i = 0; i < 15; ++i) {
    map.stage.add(map.objLayers[i])
  }
  map.stage.add(map.searchLayer)

  if (!map.scale) {
    // It's our first time viewing this map, so set up pan/zoom to center the
    // map in the viewport.
    map.pan = { x: map.bbox.w/2, y: map.bbox.h/2 };
    map.scale = 1.0;
    setScale(Math.min(map.stage.width()/map.bbox.w, map.stage.height()/map.bbox.h) * 0.95);
  }
  applyPanAndZoom(map);
}

function drawSearchResults() {
  map.searchLayer.destroyChildren()
  for (var r in search_results) {
    if (search_results[r].level != map.index) continue;
    let pos = search_results[r].obj._position;
    search_results[r].obj._target = target(map.searchLayer, pos.x, pos.y)
  }
  map.searchLayer.draw()
}

function destroyMap() {
  map.stage.destroy()
  delete map.mapLayer
  delete map.objLayers
  delete map.searchLayer
  delete map.stage
}

function updateLayers() {
  var controls = document.getElementById("layercontrols").getElementsByTagName("input");
  for (var i=0; i < controls.length; ++i) {
    map.objLayers[i].setVisible(controls[i].checked);
  }
}

function showAllLayers(visible) {
  var controls = document.getElementById("layercontrols").getElementsByTagName("input");
  for (var i=0; i < controls.length; ++i) {
    controls[i].checked = visible;
  }
  // updateLayers();
}

function performSearch(all) {
  var search = document.getElementById("search-text").value.toLowerCase()
  search_results = []
  if (search.length <= 1) return;
  for (var level=0; level < maps.length; ++level) {
    if (maps[level] && (all || level == map.index)) {
      var objs = maps[level].object_info
      for (obj in objs) {
        if (!objectMatches(objs, objs[obj], search)) continue;
        search_results.push({level: level, obj: objs[obj]})
      }
    }
  }
  search_results.sort(function(x,y) {
    if (x.obj.type < y.obj.type) return -1;
    if (x.obj.type > y.obj.type) return 1;
    return x.level - y.level
  })
  displaySearchResults()
}

function clearSearch() {
  document.getElementById("search-text").value = ''
  search_results = []
  displaySearchResults(search_results)
}

function displaySearchResults() {
  var table = document.getElementById("search-results")
  while (table.rows.length > 1) {
    table.deleteRow(1)
  }

  for (var i in search_results) {
    var result = search_results[i]
    if (i > 0 && search_results[i-1].obj._type != result.obj._type) {
      appendSearchResult(-1, null)
    }
    appendSearchResult(result.level, result.obj)
  }

  drawSearchResults()
}

function nameMatches(obj, name) {
  // TODO: look at the ObjName and ObjShort from the base obj as well
  return obj.name.toLowerCase().search(name) != -1
      || obj._type.toLowerCase().search(name) != -1
      // || (obj.SymName && obj.ObjName.toLowerCase().search(name) != -1);
}

function contentsMatch(objs, obj, name) {
  if (!obj._contents) return false
  for (i in obj._contents) {
    let item = objs[obj._contents[i]]
    if (objectMatches(objs, item, name)) return true;
  }
  return false
}

function objectMatches(objs, obj, name) {
  return nameMatches(obj, name) || contentsMatch(objs, obj, name)
}

var short_levels = [
  "🌐", "🛰",
  "🔧1", "🔧2", "🧪1", "🧪2", "🌿1", "🌿2", "🌿3", "🖧1", "🖧2", "🖧3", "🖧4", "🏀1", "🏀2", "🏀3",
  "🗡1", "🗡2", "🗡3", "🧠", "🖳"
]
function appendSearchResult(level, obj) {
  var results = document.getElementById("search-results")
  results.style.display = ''
  var row = results.insertRow(-1)
  row.className = "search-result"
  if (level < 0) {
    row.insertCell(-1);
    row.insertCell(-1).innerHTML = '<hr>';
    return;
  }
  row.onmouseenter = hilightSearchResult.bind(undefined, level, obj)
  row.onmouseleave = unhilightSearchResult.bind(undefined, obj)
  row.onclick = displayAndMark.bind(undefined, level, obj)
  row.insertCell(-1).innerHTML = short_levels[level]
  row.insertCell(-1).innerHTML = obj.name
}

function colourTarget(obj, stroke, fill) {
  if (!obj._target) return;
  obj._target.setStroke(stroke)
  obj._target.setFill(fill)
  obj._target.moveToTop()
  obj._target.draw()
}

function displayAndMark(level, obj) {
  if (map.marked) {
    colourTarget(map.marked, '#ffffff', '#ffffff')
  }
  showMap(level)
  if (map.marked != obj) {
    colourTarget(obj, '#ff00ff', '#ff80ff')
    map.marked = obj
  } else {
    map.marked = null
  }
}

function hilightSearchResult(level, obj) {
  console.log(obj)
  writeMessage(infoToTable(obj))
  if (level != map.index) return
  let pos = obj._position;
  obj._hilight = hilight(map.searchLayer, pos.x, pos.y)
  map.searchLayer.draw()
}

function unhilightSearchResult(obj) {
  if (obj._hilight) {
    obj._hilight.destroy()
    delete obj._hilight
    map.searchLayer.draw()
  }
}

function setScale(scale) {
  let oldscale = map.scale;
  map.scale = Math.max(0.2, scale);
  let ratio = map.scale/oldscale;
  map.pan.x *= ratio;
  map.pan.y *= ratio;
  applyPanAndZoom(map);
}

function tweakScale(delta) {
  setScale(map.scale + delta);
}