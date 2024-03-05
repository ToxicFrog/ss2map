#!/usr/bin/env lua
require 'util'
local vstruct = require 'vstruct'
local tagfile = require 'db.tagfile'

flags.register('help', 'h', '?') {
  help = 'display this text';
}

flags.register('gamesys') {
  help = 'path to gamesys, e.g. shock.gam';
  type = flags.string;
}

flags.register('objects') {
  help = 'list all objects in the loaded map';
}

flags.register('props') {
  help = 'list all object properties, not just name/position';
}

flags.register('inherited') {
  help = 'when listing object properties, include inherited properties';
}

local function listobjs(mis, props, inherited)
  for id,brush in pairs(mis.chunks.BRLIST.by_type[-3]) do
    local pos = brush.position
    local name = mis:getProp(brush.primal, 'SymName', true)
    printf('[%08x] %s @ (%f,%f,%f)\n',
        brush.primal, name, pos.x, pos.y, pos.z)
    if props then
      for k,v,inherited in mis:propPairs(brush.primal, inherited) do
        printf('  %s %-16s %s\n', inherited and '+' or ' ', k..':', v)
      end
    end
  end
end

local function main(...)
  local args = flags.parse {...}
  if args.help or #args < 1 then
    print('Usage: mismap [flags] [--gamesys=shock.gam] map.mis')
    print(flags.help())
    os.exit(1)
  end

  local gam; if args.gamesys then gam = tagfile(args.gamesys) end
  local mis = tagfile(args[1], gam)

  if args.objects then
    listobjs(mis, args.props, args.inherited)
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
