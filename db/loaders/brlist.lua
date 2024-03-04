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
-- I suspect that the way these are actually applied is:
-- - heading (z) first, rotating the object's x and y axes in the process; this
--   gives you "faces-towards"
-- - then pitch (not sure if x or y here); this gives you "points-at"
-- - then rotate around the object's remaining axis for bank
local Rotation = vstruct.compile('Rotation', [[ x:p2,15 y:p2,15 z:p2,15 ]])

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
  shape:{
    -- family is 1 for cylinders, 2 for pyramids, 3 for corner pyramids, and 0 for everything else
    -- index is number of extra faces if family!=0, otherwise denotes shape:
    -- 1=cube, 6=dodecahedron, 7=wedge
    [2| family:u7 face_aligned:b1 index:u8 ]
  }
  -2 primal:i4
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

-- Notes on brush types
-- 0 (solid) and 1 (air) are easy. Solid takes precedence.
-- 2 (water) takes precedence over both solid and air.
-- 3 (air2water), 4 (water2air), 5 (solid2water), 6 (solid2air), 7 (air2solid),
-- and 8 (water2solid) all turn the first brush type into the second within
-- their volume, while leaving other brushes alone. In particular 3 is usually
-- used for flooded regions -- you make the solid geometry first then slap an
-- air2water brush over it.
-- 9 (blockable) is weird, complicated, and sometimes created automatically
-- by the editor; we can probably ignore it.
-- On to the non-terrain types.
-- -5 (room) defines room boundaries. -4 (flow) defines liquid flow.
-- -3 defines the position and orientation of an object; the actual object
-- info needs to be looked up in the property chunks.
-- -2 (area) splits the map into distinct areas. This is purely an editor convenience.
-- -1 defines lighting.
-- Of these, objects and rooms are the most interesting. Rooms, in particular,
-- define the borders of a space for both sound propagation and automap purposes
-- and thus may be more useful than air brushes for some things! They can even
-- be named, although it's unclear if LGS used this feature in SS2.

-- Notes on brush shapes
-- DarkDB has some weird code around this, but some known shapes are:
-- 0x0001 (cuboid)
-- 0x0006 (dodecahedron)
-- 0x0007 (wedge)
-- 0x0200 (cylinder)
-- 0x0400 (pyramid)
-- 0x0600 (corner pyramid -- peak is over one of the corners rather than centered)
-- in the latter three cases the low byte indicates the number of *extra* faces
-- beyond the minimum needed for this shape, so 0 means 5 faces for a cylinder
-- (3 side faces + top and bottom) or 4 for a pyramid (3 side faces + bottom).


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
