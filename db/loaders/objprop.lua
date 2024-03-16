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
local proplist = require 'db.proplist'

-- A single entry that links a property value to an object ID. The property
-- name is determined by the containing field. Aggravatingly, there's no type
-- information here; instead the dark engine itself contains the field name to
-- type mapping. We can get it from newdark with the dump_props_full or
-- dump_props console commands. DarkDB handles this by hardcoding it.
local ObjProp = vstruct.compile('ObjProp', [[
  oid:i4
  size:u4
  data:s#size
]])

local function supports(tag)
  return tag:match('^P%$')
end

local function load(db, chunk, data)
  -- TODO: read the proplist.txt, select the full property name, and deserialize
  -- the property data.
  local key = chunk.tag:sub(3,-1)
  for prop in ObjProp:records(data) do
    local value = proplist.read(key, prop.data)
    -- Create a blank entity object if one doesn't already exist
    db:merge {
      meta = { id = prop.oid, type = 'entity'; };
    }
    db:object(prop.oid):setProperty(key, value)
  end
end

return {
  supports = supports;
  load = load;
}
