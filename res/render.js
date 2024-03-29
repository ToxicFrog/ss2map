// KineticJS map rendering functions //

function point(obj, x, y) {
  let cat = getCategoryForType(obj._type)
  var circ = new Kinetic.Circle({
    x: x, y: -y,
    radius: 2,
    stroke: cat.colour,
    strokeWidth: 0.5,
  });
  circ.on('mouseover', function() {
    writeMessage(objectInfo(obj._id));
    circ.setStroke('#FFFFFF');
    circ.draw();
  });
  circ.on('mouseout', function() {
    // clearMessage();
    circ.setStroke(cat.colour);
    circ.draw();
  });
  circ.on('mousedown', function() {
    lockMessage(false); writeMessage(objectInfo(id)); lockMessage(true);
    // TODO: display a persistent highlight on the locked object
  })
  map.objLayers[cat.index].add(circ);
}

function target(layer, x, y) {
  let star = new Kinetic.Star({
    x: x, y: -y,
    numPoints: 4,
    innerRadius: 0.1,
    outerRadius: 0.4,
    stroke: '#FFFFFF',
    fill: '#FFFFFF',
  })
  layer.add(star)
  return star
}

function hilight(layer, x, y) {
  var circle = new Kinetic.Circle({
    x: x, y: -y,
    radius: 16/map.scale,
    stroke: '#FF00FF',
    strokeWidth: 1,
  })
  layer.add(circle)
  return circle
}

function applyPanAndZoom(map) {
  let stage = map.stage;
  let w = stage.width();
  let h = stage.height();
  stage.setOffset({ x: (-w/2 + map.pan.x)/map.scale, y: (-h/2 + map.pan.y)/map.scale });
  stage.setScale({ x: map.scale, y: map.scale });
  stage.draw();
}
