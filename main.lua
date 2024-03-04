#!/usr/bin/env lua
require 'util'
local vstruct = require 'vstruct'
local tagfile = require 'db.tagfile'

local function hexdump(s)
  return s:gsub('.', function(c) return string.format('%02X', c:byte()) end)
end

local function main(...)
  local mis = tagfile(...)

  -- chunk names appear to be globally unique within the file, which is convenient
  for _,entry in ipairs(mis.toc) do
    printf('%08X %8d %s\n', entry.offset, entry.size, entry.tag)
  end

  for id,props in pairs(mis.props) do
    print('OBJPROP', id)
    for k,v in pairs(props) do
      print('', k, hexdump(v))
    end
  end

  return mis
end

if love then
  local render = require 'render'

  function love.keypressed(key)
    if key == 'up' then render.pan(0, -16)
    elseif key == 'down' then render.pan(0, 16)
    elseif key == 'left' then render.pan(-16, 0)
    elseif key == 'right' then render.pan(16, 0)
    elseif key == 'w' then render.zoom(1/8)
    elseif key == 's' then render.zoom(-1/8)
    end
  end

  function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
      render.pan(dx, dy)
    end
  end

  function love.draw()
    render.draw()
  end

  function love.load(argv)
    local mis = main(unpack(argv))
    love.window.setMode(1280, 960)
    render.init(mis)
  end
else
  main(...)
end

-- If the brush is a ROOM, FLOW, OBJECT, or AREA, num_faces is always 6 and the
-- faces array is empty
-- If it's a LIGHT, num_faces denotes the light type and there are no faces
-- Other types (read: type >= 0) actually have face data.
-- case BRUSH_TYPE_ROOM:
-- return new DarkBrushRoom(data);
-- case BRUSH_TYPE_FLOW:
-- return new DarkBrushFlow(data);
-- case BRUSH_TYPE_OBJECT:
-- return new DarkBrushObject(data);
-- case BRUSH_TYPE_AREA:
-- return new DarkBrushArea(data);
-- case BRUSH_TYPE_LIGHT:
-- return new DarkBrushLight(data);
-- default:
-- return new DarkBrushTerrain(data);
-- os.exit(0)
