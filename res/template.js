maps[${INDEX}] = {
  title: "${LEVEL_TITLE}",
  index: ${INDEX},
  bbox: { x: ${BBOX_X}, y: ${BBOX_Y}, w: ${BBOX_W}, h: ${BBOX_H} },
  width: ${WIDTH},
  height: ${HEIGHT},
  tile_info: {
    ${TILE_INFO}
  },
  object_info: {
    ${OBJECT_INFO}
  },
  drawTerrain: function() {
    ${WALLS}
  }
}
