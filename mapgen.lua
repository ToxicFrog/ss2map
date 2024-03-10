-- HTML map exporter for SS2.
-- Adapted from the ss1 map exporter.
local render = require 'render'

local function point(layer, x, y, colour, id)
  return "point(%d, %f, %f, '%s', '%d');" % {
    layer, x, y, colour, id }
end

local function hex(s)
  return (s:gsub(".", function(c) return ("%02X "):format(c:byte()) end):sub(1,-2))
end

local function addinfo(buf, k, v)
  if type(v) == 'string' then
    table.insert(buf, "[%q,%q]" % { k, v })
  elseif type(v) == 'number' then
    table.insert(buf, "[%q,\"%.2f\"]" % { k, v })
  else
    table.insert(buf, "[%q,%q]" % { k, tostring(v) })
  end
end

local function objectinfo(mis, brush)
  local oid = brush.primal
  local pos = brush.position
  local rot = brush.rotation
  local buf = {}

  local name = mis:getProp(brush.primal, 'SymName', true)
  local baseid = mis:derefLink(brush.primal, 'MetaProp')
  local basename = mis:getProp(baseid, 'SymName')
  local objname = mis:getProp(brush.primal, 'ObjName', true)

  addinfo(buf, "name", '%s (%d)' % { name, oid })
  addinfo(buf, "base", '%s (%d)' % { basename, baseid })
  if objname then
    addinfo(buf, "ObjName", objname)
  end
  addinfo(buf, "position", '(%.2f, %.2f, %.2f)' % { pos.x, pos.y, pos.z })
  addinfo(buf, "rotation", 'H:%d° P:%d° B:%d°' % { rot.z*180, rot.x*180, rot.y*180 })
  addinfo(buf, 'brush id', '%d' % brush.id)
  for k,v in mis:propPairs(oid, false) do
    addinfo(buf, k, v)
  end

  return [[ "%d": [%s] ]] % { oid, table.concat(buf, ",") }
end

local function drawObjects(mis)
  local draw = {}
  local info = {}

  for id,brush in pairs(mis.chunks.BRLIST.by_type[-3]) do
    local obj = objectinfo(mis, brush)
    local pos = brush.position
    table.insert(info, obj)

    table.insert(draw, point(
      0, --obj.class,
      pos.x,
      pos.y,
      '#ffff00',
      brush.primal))

    -- TODO: doors, brushes?
  end

  return draw,info
end

local function mkMap(js, mis, idx, name)
  local out = 'www'
  local map = { level = idx; name = name; }

  local objMap,objInfo = drawObjects(mis)
  render.init(mis)
  local x,y,w,h = render.getBBox()

  local data = {
    INDEX = idx;
    BASENAME = tostring(idx);
    WIDTH = 1024;
    HEIGHT = 1024;
    BBOX_X = x;
    BBOX_Y = y;
    BBOX_W = w;
    BBOX_H = h;
    TILE_INFO = "";
    OBJECT_INFO = table.concat(objInfo, ",\n    ");
    WALLS = table.concat(objMap, '\n    ');
    LEVEL_TITLE = map.name;
  }
  io.writefile(out .. "/" .. idx .. ".js", js:interpolate(data))

  if flags.parsed.genimages then
    render.drawToFile(out .. '/' .. idx .. '.png')
  end

  return map
end

local function mkViewer(html, index)
  local out = 'www'
  print('HTML', 'map.html')
  io.writefile(out .. "/" .. 'map.html', html:interpolate {
    DEFAULT_LEVEL = index[1].level;
    ALL_LEVELS = table.concat(table.mapv(index, function(map) return "%d: true" % map.level end), ",");
    LEVEL_SELECT = table.concat(
      table.mapv(
        index,
        function(map)
          return '<option value="%d">%02d - %s</option>'
            % { map.level, map.level, map.name } end),
      "\n            ");
  })
end

local function mkMaps(maplist)
  local prefix = 'res'
  print("Loading templates from %s/template.{html,js}..." % prefix)
  local html = io.readfile("%s/template.html" % prefix)
  local js = io.readfile("%s/template.js" % prefix)

  for _,file in ipairs { 'init.js', 'kinetic.js', 'loading.png', 'render.js', 'ui.js' } do
    print('STATIC', file)
    io.writefile('www/'..file, io.readfile('res/'..file))
  end

  local index = {}
  for i,mis in ipairs(maplist) do
    i = i-1
    print('JS', i..'.js', '('..mis.path..')')
    table.insert(index, mkMap(js, mis, i, mis.path))
  end

  mkViewer(html, index)
end

do return mkMaps end
