-- HTML map exporter for SS2.
-- Adapted from the ss1 map exporter.
local render = require 'render'

local function point(id, x, y)
  return "point(objs[%d], %f, %f);" % {
    id, x, y }
end

local function addinfo(buf, k, v)
  table.insert(buf._props, '%q' % k)
  if type(v) == 'string' then
    table.insert(buf, "%q: %q" % { k, v })
  elseif type(v) == 'number' then
    table.insert(buf, "%q: \"%.2f\"" % { k, v })
  elseif type(v) == 'table' then
    table.insert(buf, '%q: [%s]' % {
      k, table.concat(table.map(v, partial(string.format, '%q')), ',')
    })
  else
    table.insert(buf, "%q: %q" % { k, tostring(v) })
  end
end

local function objectinfo(db, brush)
  local oid = brush.primal
  local obj = db:object(oid)
  if not obj then return nil end
  local fqtn = obj:getFQTN()
  local pos = brush.position
  local rot = brush.rotation

  local buf = {
    -- Internal data not displayed in the property list
    '_id: %d' % oid,
    '_type: %q' % fqtn,
    '_position: { x: %f, y: %f, z: %f }' % { pos.x, pos.y, pos.z },
    _props = {};
  }

  -- High-level information and containing brush data
  addinfo(buf, "name", tostring(obj))
  if obj:getShortDesc() then
    addinfo(buf, "short desc", obj:getShortDesc())
  end
  if obj:getFullDesc() then
    addinfo(buf, "full desc", obj:getFullDesc())
  end
  -- replace ' ' with nonbreaking space, then make it breakable around slashes
  addinfo(buf, "type", fqtn) --fqtn:gsub(' ', ' '):gsub('/', ' » '))
  addinfo(buf, 'brush id', '%d' % brush.meta.id)
  addinfo(buf, "brush xyz", '(%.2f, %.2f, %.2f)' % { pos.x, pos.y, pos.z })
  addinfo(buf, "brush ϴ", 'H:%d° P:%d° B:%d°' % { rot.z*180, rot.x*180, rot.y*180 })

  -- Contents, for containers
  local contents,contentnames = {},{}
  for link in obj:getLinks('Contains') do
    table.insert(contents, tostring(link.dst))
    table.insert(contentnames, tostring(link:deref()))
  end
  if #contents > 0 then
    -- _contents contains the object IDs and is used for searching;
    -- contents contains the human-readable object names and is displayed
    -- in the side panel.
    table.insert(buf, '_contents: [%s]' % table.concat(contents, ','))
    addinfo(buf, "contents", contentnames)
  end

  -- Generic properties
  local buf_generic = { _props = {} }
  for prop in obj:getProperties(false) do
    local info = prop:pprint()
    if info:match('^Unknown: ') then
      -- strip 'unknown' prefix and truncate to 24 bytes
      info = info:sub(10,81)
    end
    addinfo(buf_generic, prop.key_full, info)
  end
  table.sort(buf_generic._props)

  return obj,
    '"%d": {%s, %s, _props: [%s, %s] }' % {
      oid,
      table.concat(buf, ','),
      table.concat(buf_generic, ','),
      table.concat(buf._props, ','),
      table.concat(buf_generic._props, ',')
    }
end

local function drawObjects(db)
  local draw = {}
  local info = {}

  for id,brush in db:objects('brush') do
    if brush.type ~= -3 then goto continue end
    local obj,objinfo = objectinfo(db, brush)
    local pos = brush.position
    -- FIXME: some T1 levels have brushes that reference nonexistent objects!
    if not obj then goto continue end
    table.insert(info, objinfo)

    table.insert(draw, point(
      obj.meta.id,
      pos.x,
      pos.y,
      obj:getFQTN()))

    -- TODO: doors, brushes?
    ::continue::
  end

  return draw,info
end

local function mkMap(js, db, idx, name)
  local output = flags.parsed.html_out
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
    OBJECT_INFO = table.concat(objInfo, ",\n    ");
    WALLS = table.concat(objMap, '\n    ');
    LEVEL_TITLE = map.name;
  }
  io.writefile(output .. "/" .. idx .. ".js", js:interpolate(data))

  if flags.parsed.genimages then
    render.drawToFile(output .. '/' .. idx)
  end

  return map
end

local function mkViewer(html, index)
  local output = flags.parsed.html_out
  print('HTML', 'map.html')
  io.writefile(output .. "/" .. 'map.html', html:interpolate {
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
  local output = flags.parsed.html_out

  print("Loading templates from res/template.{html,js}...")
  local html = love.filesystem.read("res/template.html")
  local js = love.filesystem.read("res/template.js")

  for _,file in ipairs { 'init.js', 'categories.js', 'kinetic.js', 'loading.png', 'render.js', 'ui.js' } do
    print('STATIC', file)
    io.writefile(output..'/'..file, love.filesystem.read('res/'..file))
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
