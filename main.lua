#!/usr/bin/env lua
require 'util'
local vstruct = require 'vstruct'
local tagfile = require 'db.tagfile'

local DarkDB = {}

-- a BRLIST is just a chunk header followed by a bunch of brushes packed end
-- to end until it runs out of space.

DarkDB.BrushFace = vstruct.compile('BrushFace', [[
  -- TODO: this should also be pack(2)
  texture:i2
  rotation:u2 -- texture rotation
  scale:u2
  offset:{ u2 u2 }
]])

DarkDB.Coord = vstruct.compile('Coord', 'x:f4 y:f4 z:f4')
-- Rotation is stored in "angle units". To turn angle units into radians,
-- multiply by pi/2 and divide by 2^14 (16k).
-- That means that 16k is a right angle, since 16k/16k * pi/2 = pi/2 radians.
-- a full circle is 64k, or 0xFFFF, so one of these fields is just "angle in
-- 1/64k-ths of a circle".
-- This also means that if we define it as 1.15 fixed point, it gives us a range
-- from 0.0 to 1.9..., which is the same number of pi in a circle and our
-- conversion is just "angle * pi".
DarkDB.Rotation = vstruct.compile('IntCoord', 'x:p2,15 y:p2,15 z:p2,15')

DarkDB.Brush = vstruct.compile('Brush', [[
  -- TODO: in DarkDBDefs.h this is pack(2), which worries me -- double check!
  id:u2
  time:u2
  primal:i4
  base:i2
  type:i1
  x1
  position:{ &Coord }
  size:{ &Coord } -- radius from center; double to get LxWxH
  rotation:{ &IntCoord } -- tx, ty, tz -- TODO: world or brush coordinates
  cur_face:i2
  snap_size:f4
  x18
  snap_grid:b1
  num_faces:u1
  edge:u1
  vertex:u1
  flags:u1 -- TODO: convert to bitfield?
  group:u1
  x4
  faces:{}
]])

local function main(...)
  local mis = tagfile(...)

  -- chunk names appear to be globally unique within the file, which is convenient
  for _,entry in ipairs(mis.toc) do
    printf('%08X %8d %s\n', entry.offset, entry.size, entry.tag)
  end

  brlist = mis.chunks.BRLIST
  mapparam = mis.chunks.MAPPARAM

  io.writefile('BRLIST', brlist.raw)
  local cursor = vstruct.cursor(brlist.raw)
  printf('BRLIST: v%d.%d\n', brlist.meta.major, brlist.meta.minor)
  while cursor.pos < brlist.toc.size do
    local pos = cursor.pos
    vstruct.read('{ &Brush }', cursor, brlist)
    local brush = brlist[#brlist]
    printf('  BRUSH@%x: id=%d, type=%d\n', pos, brush.id, brush.type)
    if brush.type >= 0 then
      brush.faces.n = brush.num_faces
      vstruct.read('#n * { &BrushFace }', cursor, brush.faces)
    end
  end

  print(mapparam.rotatehack)

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
