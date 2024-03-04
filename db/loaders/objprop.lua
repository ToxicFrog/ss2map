-- Loader for object property chunks. These are all named "P$" followed by the
-- property name, e.g. "P$ObjName".
--
-- A property chunk just consists of a generic chunk header followed by zero
-- or more ObjProp entries, one for each object with that property.
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

local function load(chunk, data)
  -- TODO: read the proplist.txt, select the full property name, and deserialize
  -- the property data.
  chunk.prop_name = chunk.meta.tag:sub(3,-1)
  chunk.props = {}
  for prop in ObjProp:records(data) do
    chunk.props[prop.id] = prop.value
  end
  return chunk
end

return {
  supports = supports;
  load = load;
}
