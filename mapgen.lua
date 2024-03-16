-- HTML map exporter for SS2.
-- Adapted from the ss1 map exporter.
local render = require 'render'

local function point(layer, x, y, colour, id)
  return "point(%d, %f, %f, '%s', '%d');" % {
    layer, x, y, colour, id }
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

local function objectinfo(db, brush)
  local oid = brush.primal
  local obj = assert(db:object(oid))
  local pos = brush.position
  local rot = brush.rotation
  local buf = {}

  local fqtn = obj:getFQTN()

  addinfo(buf, "name", tostring(obj))
  -- replace ' ' with nonbreaking space, then make it breakable around slashes
  addinfo(buf, "type", fqtn:gsub(' ', ' '):gsub('/', ' » '))
  addinfo(buf, 'brush id', '%d' % brush.meta.id)
  addinfo(buf, "brush xyz", '(%.2f, %.2f, %.2f)' % { pos.x, pos.y, pos.z })
  addinfo(buf, "brush ϴ", 'H:%d° P:%d° B:%d°' % { rot.z*180, rot.x*180, rot.y*180 })
  for prop in obj:getProperties(false) do
    addinfo(buf, prop.key_full, prop:pprint())
  end

  return [[ "%d": [%s] ]] % { oid, table.concat(buf, ",") }
end

local function drawObjects(db)
  local draw = {}
  local info = {}

  for id,brush in db:objects('brush') do
    if brush.type ~= -3 then goto continue end
    local obj = objectinfo(db, brush)
    local pos = brush.position
    table.insert(info, obj)

    table.insert(draw, point(
      0, --obj.class,
      pos.x,
      pos.y,
      '#ffff00',
      brush.primal))

    -- TODO: doors, brushes?
    ::continue::
  end

  return draw,info
end

local function mkMap(js, db, idx, name)
  local out = 'www'
  local map = { level = idx; name = name; }

  local objMap,objInfo = drawObjects(db)
  render.init(db)
  local x,y,w,h = render.getBBox()

  local data = {
    INDEX = idx;
    BASENAME = tostring(idx);
    WIDTH = 1024;
    HEIGHT = 1024;
    BBOX_X = x;
    BBOX_Y = -(y+h);
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
  for i,db in ipairs(maplist) do
    i = i-1
    print('JS', i..'.js', '('..db.name..')')
    table.insert(index, mkMap(js, db, i, db.name))
  end

  mkViewer(html, index)
end

do return mkMaps end
