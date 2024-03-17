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

-- Only register flags the first time we're loaded.
if not flags.registered.rotatehack then
  flags.register('rotatehack') {
    help = 'Rotate the view of the map so it matches up with the in-game compass and automap rather than with ShockEd'
  }

  flags.register('renderscale') {
    help = 'Scale the HTML map to this value';
    type = flags.number;
    default = 2.0;
  }
end

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

local function init(db)
  -- rotatehack = mis.chunks.MAPPARAM.rotatehack
  rotatehack = false
  brushes = {}

  -- Group brushes based on what we need in the different rendering passes
  for _,brush in db:objects('brush') do
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
end

-- convert worldspace coordinates to screenspace coordinates
local function world2screen(x, y)
  do return x,y end
end

local function drawRotatedRectangle(mode, x, y, width, height, angle)
  -- We cannot rotate the rectangle directly, but we
  -- can move and rotate the coordinate system.
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)
  love.graphics.rectangle(mode, -width, -height, width*2, height*2)
  love.graphics.pop()
end

-- Returns the on-screen width and height of a brush's bounding box by applying
-- its pitch and bank rotation fields. (Heading is applied when we actually
-- draw it). For 90° rotations this is exact; other rotations are approximate.
local function getRotatedWH(brush)
  local x_size,y_size,z_size = brush.size.x, brush.size.y, brush.size.z
  local bank, pitch = brush.rotation.x*math.pi, brush.rotation.y*math.pi

  -- apply bank (rotaton around x) first, affecting the relationship between the
  -- y and z axes.
  y_size,z_size =
    y_size * bank:cos() + z_size * bank:sin(),
    y_size * bank:sin() + z_size * bank:cos()

  -- now apply pitch, affecting the rotation between x and z
  x_size,z_size =
    x_size * pitch:cos() + z_size * pitch:sin(),
    x_size * pitch:sin() + z_size * pitch:cos()

  return x_size, y_size
end

local function drawBrush(mode, brush)
  local x,y = world2screen(brush.position.x, brush.position.y)
  local w,h = getRotatedWH(brush)
  drawRotatedRectangle(mode, x, y, w, h, brush.rotation.z*math.pi)
end

local tx,ty = 0,0
local scale = 2.0

local function pan(dx, dy)
  tx,ty = tx+(dx/scale), ty+(dy/scale)
end

local function zoom(dz)
  scale = scale + dz
end

local function prepare()
  local w,h = love.window.getMode()
  love.graphics.translate(w/2, h/2)
  love.graphics.scale(scale, scale)
  love.graphics.translate(tx, ty)
  love.graphics.scale(1, -1) -- invert Y since LGS uses southwest rather than northwest gravity
  love.graphics.setLineWidth(1/scale)
  if flags.parsed.rotatehack then
    if rotatehack then
      love.graphics.rotate(math.rad(180))
    else
      love.graphics.rotate(math.rad(90))
    end
  end
end

-- Get the lowest (x,y) value that could be overlapped by this brush.
-- Don't worry about rotation, just assume worst-case rotation around every axis.
local function getBrushMinima(brush)
  return
    brush.position.x - math.max(brush.size.x, brush.size.y, brush.size.z) * 1.1,
    brush.position.y - math.max(brush.size.x, brush.size.y, brush.size.z) * 1.1
end

-- As above but finds the maximum possible overlapping coordinates.
local function getBrushMaxima(brush)
  return
    brush.position.x + math.max(brush.size.x, brush.size.y, brush.size.z) * 1.1,
    brush.position.y + math.max(brush.size.x, brush.size.y, brush.size.z) * 1.1
end

-- Get the x,y bounding box for the entire level, as (x,y,w,h), based on brush
-- positions and sizes.
local function getBBoxAux(minX, minY, maxX, maxY, brushes, ...)
  if not brushes then return minX, minY, maxX-minX, maxY-minY end

  for _,brush in ipairs(brushes) do
    local brushX,brushY = getBrushMinima(brush)
    minX = minX:min(brushX)
    minY = minY:min(brushY)
    brushX,brushY = getBrushMaxima(brush)
    maxX = maxX:max(brushX)
    maxY = maxY:max(brushY)
  end

  return getBBoxAux(minX, minY, maxX, maxY, ...)
end

local function getBBox()
  return getBBoxAux(
    math.huge, math.huge, -math.huge, -math.huge,
    brushes.air, brushes.decor, brushes.walls, brushes.objects)
end

local function prepareCanvas()
  scale = flags.parsed.renderscale
  local x,y,w,h = getBBox()
  love.graphics.scale(scale, -scale) -- invert Y since LGS uses southwest rather than northwest gravity
  love.graphics.translate(-x, -(y+h))
  love.graphics.setColor(1,1,0,0.5)
  love.graphics.setLineWidth(scale/2)
  love.graphics.rectangle('line', x, y, w, h)
  love.graphics.setColor(1,1,1,0.5)
  love.graphics.line(0, -100, 0, 100)
  love.graphics.line(-100, 0, 100, 0)
  love.graphics.circle('line', 0, 0, 50)
  love.graphics.setLineWidth(2/scale)
end

-- Draw outer volumes of air brushes.
local function drawAir(brushes)
  -- draw outer edge of each brush
  love.graphics.setLineWidth(4/scale)
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
    -- love.graphics.setColor(1, 1, 1, 0.5)
    -- local x,y = world2screen(brush.position.x, brush.position.y)
    -- love.graphics.circle('fill', x, y, 1)
    local obj = getmetatable(brush).__db:object(brush.primal)
    if obj:getProperty('TransDoor') then
      -- TODO: this should use the PhysDims property on the object, once we
      -- know how to read it accurately.
      love.graphics.setColor(0, 0, 0, 1)
      drawBrush('fill', brush)
      love.graphics.setColor(1, 1, 0, 1)
      drawBrush('line', brush)
    end
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
  if brush.shape.family ~= 0 or brush.shape.index ~= 1 then -- not a cube? o noes
    love.graphics.setColor(1, 0, 0, 0.2)
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
  love.graphics.push()
  if love.graphics.getCanvas() then
    prepareCanvas()
  else
    prepare()
  end
  drawAir(brushes.air)
  drawDecorations(brushes.decor)
  drawWalls(brushes.walls)
  drawObjects(brushes.objects)
  -- drawUnknown(brushes.other)
  drawBadBrushes(brushes.air, brushes.walls, brushes.decor)
  love.graphics.pop()
end

local function drawToFile(filename)
  local x,y,w,h = getBBox()
  scale = 0.5
  tx, ty = 0, 0
  love.graphics.clear()
  draw()
  love.graphics.present()
  local renderscale = flags.parsed.renderscale
  local canvas = love.graphics.newCanvas(w*renderscale+1, h*renderscale+1)
  love.graphics.setCanvas {
    canvas;
    stencil = true, depth = false;
  }
  draw()
  love.graphics.setCanvas()
  print('PNG', filename)
  io.writefile(filename, canvas:newImageData():encode('png'):getString())
end

return {
  init = init;
  draw = draw;
  zoom = zoom;
  pan = pan;
  drawToFile = drawToFile;
  getBBox = getBBox;
}
