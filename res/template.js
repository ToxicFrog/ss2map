maps[${INDEX}] = {
  title: "${LEVEL_TITLE}",
  short: "${SHORT}",
  icon: "${ICON}",
  index: ${INDEX},
  bbox: { x: ${BBOX_X}, y: ${BBOX_Y}, w: ${BBOX_W}, h: ${BBOX_H} },
  object_info: {
    ${OBJECT_INFO}
  },
  drawTerrain: function(objs) {
    ${WALLS}
  }
}
