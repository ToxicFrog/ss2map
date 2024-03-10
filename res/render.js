// KineticJS map rendering functions //

function line(x1, y1, x2, y2, colour) {
  map.mapLayer.add(new Kinetic.Line({
    points: [x1*SCALE, (map.height-y1)*SCALE, x2*SCALE, (map.height-y2)*SCALE],
    stroke: colour,
  }));
}

function point(layer, x, y, colour, id) {
  var obj = new Kinetic.Circle({
    x: x, y: -y,
    radius: 2,
    stroke: colour,
    strokeWidth: 0.5,
    //fill: colour,
  });
  obj.on('mouseover', function() {
    writeMessage(objectInfo(id));
  });
  obj.on('mousedown', function() { lockMessage(false); writeMessage(objectInfo(id)); lockMessage(true); })
  map.objLayers[layer].add(obj);
}

function target(layer, x, y) {
  layer.add(new Kinetic.Star({
    x: x, y: -y,
    numPoints: 4,
    innerRadius: 0.1*SCALE,
    outerRadius: 0.4*SCALE,
    stroke: '#FFFFFF',
    fill: '#FFFFFF',
  }))
}

function hilight(layer, x, y) {
  var circle = new Kinetic.Circle({
    x: x, y: -y,
    radius: SCALE,
    stroke: '#FF00FF',
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
