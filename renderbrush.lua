-- Code for rendering individual brushes.
-- This gets its own library so that we can more tidily have different rendering
-- paths for different brush types.

local function drawRotatedRectangle(mode, x, y, width, height, angle)
  -- We cannot rotate the rectangle directly, but we
  -- can move and rotate the coordinate system.
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)
  love.graphics.rectangle(mode, -width, -height, width*2, height*2)
  love.graphics.pop()
end

local function drawPolygon(mode, x, y, w, h, sides, angle)
  local tf = love.math.newTransform():scale(w, h)
  local theta = math.pi * 2 / sides
  local points = {}
  for i=1,sides do
    local x,y = tf:transformPoint(0, 1)
    table.insert(points, x)
    table.insert(points, y)
    tf:rotate(theta)
  end
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)
  love.graphics.polygon(mode, points)
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

local renderbrush = {}

function renderbrush.box(mode, brush)
  local x,y = brush.position.x, brush.position.y
  local w,h = getRotatedWH(brush)
  return drawRotatedRectangle(mode, x, y, w, h, brush.rotation.z*math.pi)
end

function renderbrush.wedge(mode, brush)
  return renderbrush.box(mode, brush)
end

function renderbrush.d12(mode, brush)
  local x,y = brush.position.x, brush.position.y
  local w,h = getRotatedWH(brush)
  drawPolygon(mode, x, y, w, h, 5, brush.rotation.z*math.pi)
  drawPolygon(mode, x, y, w*0.6, h*0.6, 5, brush.rotation.z*math.pi)
  -- TODO: render lines connecting interior vertices to exterior
end

function renderbrush.cylinder(mode, brush)
  if brush.rotation.x > 1/6 or brush.rotation.y > 1/6 then
    -- Tilted more than 30° off vertical; approximate it as a box
    return renderbrush.box(mode, brush)
  end
  local x,y = brush.position.x, brush.position.y
  local w,h = getRotatedWH(brush)
  local sides = brush.shape.index+3
  -- If face_aligned is set, there is a face rather than a vertex at 0° heading.
  local rotation = brush.rotation.z + (brush.shape.face_aligned and 1/sides or 0)
  return drawPolygon(mode, x, y, w, h, sides, rotation*math.pi)
end

function renderbrush.cone(mode, brush)
  -- TODO: render interior lines marking it as a cone
  return renderbrush.cylinder(mode, brush)
end

function renderbrush.offsetCone(mode, brush)
  -- TODO: render interior lines marking it as a cone
  return renderbrush.cylinder(mode, brush)
end

function renderbrush.draw(mode, brush)
  local shape = brush.shape
  if shape.family == 0 then
    if shape.index == 1 then return renderbrush.box(mode, brush)
    elseif shape.index == 6 then return renderbrush.d12(mode, brush)
    elseif shape.index == 7 then return renderbrush.wedge(mode, brush)
    end
  elseif shape.family == 1 then
    return renderbrush.cylinder(mode, brush)
  elseif shape.family == 2 then
    return renderbrush.cone(mode, brush)
  elseif shape.family == 3 then
    return renderbrush.offsetCone(mode, brush)
  end
  -- don't know how to draw this
  -- error('unknown primal '..brush.type..':'..shape.family..','..shape.index)
  love.graphics.setColor(1, 0, 0, 0.5)
  return renderbrush.box('line', brush)
end

return renderbrush
