-- BRLIST, the mission file brush list
-- This consists of a standard chunk header followed by brushes packed end-to-end.
local vstruct = require 'vstruct'

-- This isn't actually used anywhere, but we need to read them in order to get
-- to the end of the brush anyways, and maybe we'll want to draw textures
-- someday?
local BrushFace = vstruct.compile('BrushFace', [[
  texture:i2
  rotation:u2
  scale:u2
  offset:{ u2 u2 }
]])

-- Coordinates. Might want to move this into a common library someday.
local Coord = vstruct.compile('Coord', [[ x:f4 y:f4 z:f4 ]])

-- Rotation. These are all in Dark engine "angle units", 1/64k-ths of a circle.
-- We read them as 1.15 fixed point values, which gives a range of [0,2), which
-- means we can convert them into radians just by multiplying by pi.
local Rotation = vstruct.compile('Rotation', [[ x:p2,15 y:p2,15 z:p2,15 ]])
do
  -- Wrap the reader to convert to radians at read time.
  local _read = Rotation.read
  function Rotation.read(...)
    local rot = _read(...)
    rot.x,rot.y,rot.z = rot.x*math.pi, rot.y*math.pi, rot.z*math.pi
    return rot
  end
end

-- An actual brush definition. Some of these fields are really hairy and
-- require additional postprocessing that we don't do yet.
-- Brushes define a LOT of things, including
-- - positive and negative terrain
-- - lights
-- - room and area volumes
-- - object positions (all other object properties are stored elsewhere)
-- and because of this some fields are overloaded or have unintuitive usage.
-- Note that Dromed uses a subtractive-first approach: air brushes are placed
-- first to define open volumes, and then solid brushes are placed inside them
-- to add detail.
local Brush = vstruct.compile('Brush', [[
  id:u2
  time:u2
  primal:i4 -- this contains the shape for terrain, and the oid for rooms and objects
  base:i2 -- base archetype id for objects?
  type:i1 -- brush type, e.g. solid, air
  x1
  position:{ &Coord }
  size:{ &Coord } -- distance from center; double to get LxWxH
  rotation:{ &Rotation } -- tx, ty, tz -- TODO: world or brush coordinates? What order?
  cur_face:i2
  snap_size:f4
  x18
  snap_grid:b1
  nrof_faces:u1 -- depending on the brush type this might be full of lies
  edge:u1
  vertex:u1
  flags:u1 -- TODO: convert to bitfield?
  group:u1
  x4
  faces:{}
]])

local function supports(tag)
  return tag == 'BRLIST'
end

-- TODO: additional postprocessing; stringify brush types and shapes, add
-- convenience functions for rendering, intersection detection, etc. We might
-- want to pull these out into separate files for different kinds of brush.
local function load(chunk, data)
  local cursor = vstruct.cursor(data)
  while cursor.pos < chunk.toc.size do
    vstruct.read('{ &Brush }', cursor, chunk)
    local brush = chunk[#chunk]
    if brush.type >= 0 then
      -- Only terrain-type brushes use nrof_faces for the actual number of faces
      brush.faces.n = brush.nrof_faces
      vstruct.read('#n * { &BrushFace }', cursor, brush.faces)
    end
  end
  return chunk
end

return {
  supports = supports;
  load = load;
}
