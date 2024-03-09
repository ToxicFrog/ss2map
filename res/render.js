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
    radius: SCALE/4,
    stroke: colour,
    //fill: colour,
  });
  obj.on('mouseover', function() {
    writeMessage(objectInfo(id));
  });
  obj.on('mousedown', function() { lockMessage(false); writeMessage(objectInfo(id)); lockMessage(true); })
  map.objLayers[layer].add(obj);
}

function target(layer, x, y) {
  console.log("target", x, y, (map.width/2) + x, (map.height/2) - y)
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
  console.log("highlight", x, y, (map.width/2) + x, (map.height/2) - y)
  var circle = new Kinetic.Circle({
    x: x, y: -y,
    radius: SCALE,
    stroke: '#FF00FF',
  })
  layer.add(circle)
  return circle
}

