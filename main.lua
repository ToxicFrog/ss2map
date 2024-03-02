#!/usr/bin/env lua
require 'util'
local vstruct = require 'vstruct'
local tagfile = require 'db.tagfile'

local function main(...)
  local mis = tagfile(...)

  -- chunk names appear to be globally unique within the file, which is convenient
  for _,entry in ipairs(mis.toc) do
    printf('%08X %8d %s\n', entry.offset, entry.size, entry.tag)
  end

  brlist = mis.chunks.BRLIST
  mapparam = mis.chunks.MAPPARAM
end

if love then
  print("love2d detected")
  -- return scaling factor for screen relative to world
  -- i.e. if this returns 32,32 one world cell is 32x32px on screen
  local function screenscale(world)
    local w, h = love.window.getMode()
    local world_w, world_h = world:size()
    return w/world_w, h/world_h
  end

  -- convert worldspace coordinates to screenspace coordinates
  local function world2screen(world, x, y)
    do return x,-y end
    local w,h = love.window.getMode()
    return x/0.5 + w/2, -y/0.5 + h/2
    -- local sx,sy = screenscale(world)
    -- return x * sx, y * sy
  end

  local function drawRotatedRectangle(mode, x, y, width, height, angle)
    -- We cannot rotate the rectangle directly, but we
    -- can move and rotate the coordinate system.
    angle = angle * math.pi -- convert dark angle units to radians
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    -- love.graphics.rectangle(mode, 0, 0, width, height) -- origin in the top left corner
  	love.graphics.rectangle(mode, -width/2, -height/2, width, height) -- origin in the middle
    love.graphics.pop()
  end

  local tx,ty = 0,0
  local zoom = 1.5

  function love.keypressed(key)
    if key == 'up' then ty = ty + 16
    elseif key == 'down' then ty = ty - 16
    elseif key == 'left' then tx = tx - 16
    elseif key == 'right' then tx = tx + 16
    elseif key == 'z' then tx,ty,zoom = 0,0,1.5
    elseif key == 'w' then zoom = zoom + 1/8
    elseif key == 's' then zoom = zoom - 1/8
    end
  end

  function love.draw()
    local w,h = love.window.getMode()
    love.graphics.push()
    love.graphics.translate(w/2+tx, h/2+ty)
    love.graphics.scale(zoom)
    if mapparam.rotatehack then
      love.graphics.rotate(math.rad(180))
    else
      love.graphics.rotate(math.rad(90))
    end
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle('fill', 0, 0, w, h)
    love.graphics.setColor(1, 0, 1, 0.5)
    for _,brush in ipairs(brlist) do
      local mode = 'line'
      if brush.type == -3 then
        -- BRUSH_TYPE_OBJECT
        love.graphics.setColor(0.5, 0, 1, 0.1)
        local x,y = world2screen(nil, brush.position.x, brush.position.y)
        love.graphics.circle('line', x, y, 2)
        goto continue
      elseif brush.type < 0 then
        -- non-object non-terrain brushes
        goto continue
      elseif brush.type == 0 then -- solid
        love.graphics.setColor(0, 1, 1, 0.6)
      elseif brush.type == 1 then -- air
        love.graphics.setColor(1, 1, 1, 0.5)
        -- goto continue
      elseif brush.type == 2 then -- water
        love.graphics.setColor(0, 0, 1, 0.5)
        mode = 'fill'
      else
        -- other terrain brush, such as FLOOD/EVAPORATE or BLOCKABLE
        love.graphics.setColor(1, 0, 1, 0.5)
        -- goto continue
      end
      local x,y = world2screen(nil, brush.position.x, brush.position.y)
      if brush.rotation.x + brush.rotation.y + brush.rotation.z ~= 0 then
        if brush.rotation.x + brush.rotation.y ~= 0 then
          love.graphics.setColor(1, 0, 0, 0.3)
        else
          -- love.graphics.setColor(0, 1, 0, 1)
          -- print(brush.rotation.z)
        end
      end
      drawRotatedRectangle(mode, x, y, brush.size.x * 2, brush.size.y * 2, brush.rotation.z)
      -- love.graphics.rectangle('line', x, y, (brush.size.x * 2)/0.5, (brush.size.y * 2)/0.5)
      ::continue::
    end
    love.graphics.pop()
  end

  function love.load(argv)
    main(unpack(argv))
    love.window.setMode(1024, 1024)
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
