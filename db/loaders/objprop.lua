-- Loader for object property chunks. These are all named "P$" followed by the
-- property name, e.g. "P$ObjName".
--
-- A property chunk just consists of a generic chunk header followed by zero
-- or more ObjProp entries, one for each object with that property.
--
-- Note that objprops stored in MIS files only store those that differ from the
-- default properties in the gamesys. In order to look those up, we also need
-- to process the MetaProp link chunk (L$MetaProp); the destination of each link
-- is going to be the parent object ID.
local vstruct = require 'vstruct'

-- A single entry that links a property value to an object ID. The property
-- name is determined by the containing field. Aggravatingly, there's no type
-- information here; instead the dark engine itself contains the field name to
-- type mapping. We can get it from newdark with the dump_props_full or
-- dump_props console commands. DarkDB handles this by hardcoding it.
local ObjProp = vstruct.compile('ObjProp', [[
  id:i4
  size:u4
  value:s#size
]])

local function supports(tag)
  return tag:match('^P%$')
end

local function load(self, chunk, data)
  -- TODO: read the proplist.txt, select the full property name, and deserialize
  -- the property data.
  chunk.prop_name = chunk.meta.tag:sub(3,-1)
  chunk.props = {}
  for prop in ObjProp:records(data) do
    -- per-chunk maps for property -> id -> value
    chunk.props[prop.id] = prop.value
    -- also update the per-file id -> property -> value map
    self:addProp(prop.id, chunk.prop_name, prop.value)
  end
  return chunk
end

return {
  supports = supports;
  load = load;
}
