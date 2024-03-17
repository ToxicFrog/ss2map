// KineticJS map rendering functions //

function line(x1, y1, x2, y2, colour) {
  map.mapLayer.add(new Kinetic.Line({
    points: [x1*SCALE, (map.height-y1)*SCALE, x2*SCALE, (map.height-y2)*SCALE],
    stroke: colour,
  }));
}

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
    obj.setStroke('#FFFFFF');
    obj.draw();
  });
  circ.on('mouseout', function() {
    // clearMessage();
    obj.setStroke(colour);
    obj.draw();
  });
  circ.on('mousedown', function() {
    lockMessage(false); writeMessage(objectInfo(id)); lockMessage(true);
    // TODO: display a persistent highlight on the locked object
  })
  console.log(obj)
  console.log(cat)
  console.log(map.objLayers)
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
