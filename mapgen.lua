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

local function mkMap(js, mapinfo, idx)
  local output = flags.parsed.html_out
  local map = { level = idx; name = mapinfo.name; }

  local objMap,objInfo = drawObjects(mapinfo.db)
  render.init(mapinfo.db)
  local x,y,w,h = render.getBBox()

  local data = {
    LEVEL_TITLE = mapinfo.name;
    SHORT = mapinfo.short or '';
    ICON = mapinfo.icon or '';
    INDEX = idx;
    BASENAME = tostring(idx);
    BBOX_X = x;
    BBOX_Y = -(y+h);
    BBOX_W = w;
    BBOX_H = h;
    OBJECT_INFO = table.concat(objInfo, ",\n    ");
    WALLS = table.concat(objMap, '\n    ');
  }
  io.writefile(output .. "/" .. idx .. ".js", js:interpolate(data))

  if flags.parsed.genimages then
    render.drawToFile(output .. '/' .. idx)
  end

  return map
end

local cat_template = [[
  {
    name: "${name}",
    colour: "${colour}",
    visible: ${visible},
    description: "${info}",
    types: [ ${typelist} ]
  },
]]
local function mkCategoryList(mapinfo)
  local buf = { 'var CATEGORIES = [' }
  for _,cat in ipairs(mapinfo.categories) do
    cat.typelist = {}
    for _,type in ipairs(cat.types) do table.insert(cat.typelist, '"%s"' % type) end
    cat.typelist = table.concat(cat.typelist, ',')
    cat.visible = cat.visible or false
    table.insert(buf, cat_template:interpolate(cat))
  end
  table.insert(buf, '];')
  return table.concat(buf, '\n')
end

local function mkViewer(html, info, index)
  -- TODO: use info to generate categories.js
  local output = flags.parsed.html_out

  print('FILTERS', 'filters.js')
  io.writefile(output .. '/filters.js', mkCategoryList(info))

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

local function mkMaps(info)
  local output = flags.parsed.html_out

  print("Loading templates from res/template.{html,js}...")
  local html = love.filesystem.read("res/template.html")
  local js = love.filesystem.read("res/template.js")

  for _,file in ipairs { 'init.js', 'categories.js', 'kinetic.js', 'loading.png', 'render.js', 'ui.js' } do
    print('STATIC', file)
    io.writefile(output..'/'..file, love.filesystem.read('res/'..file))
  end

  local index = {}
  for i,map in ipairs(info.maps) do
    -- each map is going to have the keys { name, db, files, short, icon } with
    -- icon and short being optional
    i = i-1
    print('JS', i..'.js', '(%s: %s)' % { map.files[1], map.name })
    table.insert(index, mkMap(js, map, i))
  end

  mkViewer(html, info, index)
end

return mkMaps
