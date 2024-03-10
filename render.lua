-- Renderer for the map, using the love2d API.
--
-- This uses a multi-pass approach over different kinds of brushes.
-- First, it uses the stencil buffer to draw the entire volume of air brushes,
-- which gives a sort of useful outline of the level.
-- Then it tries to draw solid brushes. In the future I want to differentiate
-- these into "walls" which extend from the floor to the ceiling and block
-- player movement, and "decorations" which do not, and render the former in
-- solid black; however, this requires more sophisticated reasoning about brush
-- volumes, so for now it takes a best guess an draws the former in bright blue
-- and the latter in dim blue.
-- Water brushes are not currently supported (and are rarely used in SS2).
-- Getting these to look good will probably require using the love2d depth buffer.
-- Finally, we draw "bad brushes", which are brushes for which the rendering is
-- known to be wrong.

local rotatehack = false;
local brushes = {}
local brushtypes = {
  [-5] = 'rooms';
  [-3] = 'objects';
  [0] = 'solid';
  [1] = 'air';
  [6] = 'air'; -- solid2air
  [2] = 'water';
}

-- Sort brushes by floor height ascending.
local function brushSort(brushes)
  table.sort(brushes, function(b1, b2)
    local b1f = b1.position.z - b1.size.z
    local b2f = b2.position.z - b2.size.z
    return b1f < b2f
  end)
end

-- Quick and dirty test to see if the given point lies inside the brush.
-- Only supports z-rotation.
local function brushContains(brush, x, y, z)
  local tf = love.math.newTransform()
  local pos = brush.position
  tf:rotate(brush.rotation.z * math.pi)
  -- Get the x,y of our point within the brush's frame of reference
  x,y = tf:transformPoint(x - pos.x, y - pos.y)
  z = z - pos.z
  return x:abs() <= brush.size.x
    and y:abs() <= brush.size.y
    and z:abs() <= brush.size.z
end

-- Very quick and dirty "does this brush extend from the floor to the ceiling" check.
-- TODO: try this with both air and rooms.
local function isWall(brush, rooms)
  local x,y,z = brush.position.x, brush.position.y, brush.position.z
  for _,room in ipairs(rooms) do
    if brushContains(room, x, y, z) then
      -- print('room membership test:')
      -- print('', 'room', room.position.x, room.position.y, room.position.z, room.rotation.z * math.pi)
      -- print('', 'point', x, y, z)
      z = z - room.position.z
      -- We're a wall if our ceiling extends to the room's ceiling, and our
      -- floor extends to the room's floor.
      return z + brush.size.z >= room.size.z
        and z - brush.size.z <= room.size.z
    end
  end
  -- Not in any room??
  return false
end

local function init(mis)
  rotatehack = mis.chunks.MAPPARAM.rotatehack

  -- Group brushes based on what we need in the different rendering passes
  for _,brush in ipairs(mis.chunks.BRLIST) do
    local typename = brushtypes[brush.type] or 'other'
    brushes[typename] = brushes[typename] or {}
    table.insert(brushes[typename], brush)
  end
  -- Divide wall brushes into decor (has open space above/below) and true walls
  brushes.decor = {}
  brushes.walls = {}
  for _,brush in ipairs(brushes.solid) do
    if isWall(brush, brushes.rooms) then
      table.insert(brushes.walls, brush)
    else
      table.insert(brushes.decor, brush)
    end
  end

  -- Z-order sort
  brushSort(brushes.air)
  brushSort(brushes.walls)

  print('Loaded:')
  for k,v in pairs(brushes) do
    print('', k, #v)
  end
end

-- convert worldspace coordinates to screenspace coordinates
local function world2screen(x, y)
  do return x,-y end
end

local function drawRotatedRectangle(mode, x, y, width, height, angle)
  -- We cannot rotate the rectangle directly, but we
  -- can move and rotate the coordinate system.
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(-angle)
  love.graphics.rectangle(mode, -width, -height, width*2, height*2)
  love.graphics.pop()
end

local function drawBrush(mode, brush)
  local x,y = world2screen(brush.position.x, brush.position.y)
  drawRotatedRectangle(mode, x, y, brush.size.x, brush.size.y, brush.rotation.z*math.pi)
end

local tx,ty = 0,0
local scale = 2.0

local function pan(dx, dy)
  tx,ty = tx+(dx/scale), ty+(dy/scale)
end

local function zoom(dz)
  scale = scale + dz
end

local function prepare(w, h)
  love.graphics.translate(w/2, h/2)
  love.graphics.scale(scale)
  love.graphics.translate(tx, ty)
  love.graphics.setLineWidth(1/scale)
  if rotatehack then
    love.graphics.rotate(math.rad(180))
  else
    love.graphics.rotate(math.rad(90))
  end
end

-- Draw outer volumes of air brushes.
local function drawAir(brushes)
  -- draw outer edge of each brush
  love.graphics.setLineWidth(2/scale)
  for _,brush in ipairs(brushes) do
    love.graphics.setColor(0, 0.5, 0.7, 1)
    drawBrush('line', brush)
  end
  love.graphics.setLineWidth(1/scale)

  -- then generate a stencil for the room interiors
  love.graphics.clear(false, true, false)
  love.graphics.stencil(function()
    for _,brush in ipairs(brushes) do
      love.graphics.setColor(1, 1, 1, 1)
      drawBrush('fill', brush)
    end
  end, 'replace', 1)

  -- and fill it
  love.graphics.setStencilTest('greater', 0)
  love.graphics.setColor(0, 0.1, 0.15, 1)
  love.graphics.rectangle('fill', -1024, -1024, 2048, 2048)
  love.graphics.setStencilTest()
end

-- Draw brushes that leave some space above or below them.
local function drawDecorations(brushes)
  love.graphics.clear(false, true, false)
  love.graphics.stencil(function()
    for _,brush in ipairs(brushes) do
      drawBrush('line', brush)
    end
  end)
  love.graphics.setStencilTest('greater', 0)
  love.graphics.setColor(0, 1, 1, 0.4)
  love.graphics.rectangle('fill', -1024, -1024, 2048, 2048)
  love.graphics.setStencilTest()
end

-- Draw brushes that connect to both the floor and ceiling.
local function drawWalls(brushes)
  for _,brush in ipairs(brushes) do
    -- love.graphics.setColor(0, 0, 0, 1)
    -- drawBrush('fill', brush)
    love.graphics.setColor(0, 1, 1, 1)
    drawBrush('line', brush)
  end
end

-- Stencil out fully solid regions of the level.
local function drawStencils(brushes)
  -- someday, do this using the air brushes
end

local function drawObjects(brushes)
  for _,brush in ipairs(brushes) do
    love.graphics.setColor(1, 0, 0, 0.5)
    local x,y = world2screen(brush.position.x, brush.position.y)
    love.graphics.circle('fill', x, y, 0.5)
  end
end

local function drawUnknown(brushes)
  for _,brush in ipairs(brushes) do
    love.graphics.setColor(1, 0, 1, 0.5)
    drawBrush('line', brush)
  end
end

-- A "bad" brush is one we don't know how to draw accurately yet.
-- At present, this draws in yellow brushes where all rotations are
-- multiples of 180, in pink brushes where they are rotations of 90,
-- and in red brushes rotated at other angles.
local function drawBadBrush(brush)
  local xr,yr = brush.rotation.x, brush.rotation.y
  local xr90 = xr % 0.5 == 0
  local yr90 = yr % 0.5 == 0
  local xr180 = xr % 1 == 0
  local yr180 = yr % 1 == 0
  if xr + yr ~= 0 then
    if xr180 and yr180 then
      love.graphics.setColor(1, 0, 1, 1.0)
    elseif xr90 and yr90 then
      love.graphics.setColor(1, 0, 1, 1.0)
    else
      love.graphics.setColor(1, 1, 0, 1.0)
    end
  elseif brush.shape.family ~= 0 or brush.shape.index ~= 1 then -- not a cube? o noes
    love.graphics.setColor(1, 0, 0, 1.0)
  else
    return
  end
  drawBrush('line', brush)
end

local function drawBadBrushes(brushes, ...)
  if not brushes then return end
  for _,brush in ipairs(brushes) do
    drawBadBrush(brush)
  end
  return drawBadBrushes(...)
end

local function draw()
  local w,h = love.window.getMode()
  love.graphics.push()
  prepare(w, h)
  drawAir(brushes.air)
  drawDecorations(brushes.decor)
  drawWalls(brushes.walls)
  drawObjects(brushes.objects)
  -- drawUnknown(brushes.other)
  drawBadBrushes(brushes.air, brushes.walls, brushes.decor)
  love.graphics.pop()
end

return {
  init = init;
  draw = draw;
  zoom = zoom;
  pan = pan;
}
