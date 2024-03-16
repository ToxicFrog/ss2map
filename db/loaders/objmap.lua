-- Loader for OBJ_MAP chunks. These contain an entity ID to name mapping.
--
local vstruct = require 'vstruct'

local ObjMapEntry = vstruct.compile('ObjMapEntry', [[
  id:i4
  name:c4
]])

local function supports(tag)
  return tag == 'OBJ_MAP'
end

local function load(db, chunk, data)
  for record in ObjMapEntry:records(data) do
    db:merge {
      meta = { id = record.id; type = 'entity'; };
      name = record.name:sub(1,-2); -- drop the trailing nul
    }
  end
end

return {
  supports = supports;
  load = load;
}
