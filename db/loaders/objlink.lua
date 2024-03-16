-- Loader for object link chunks. These are all named "L$" followed by the
-- link type, e.g. "L$MetaProp".
--
-- For now we just store
local vstruct = require 'vstruct'

-- A single entry that links a property value to an object ID. The property
-- name is determined by the containing field. Aggravatingly, there's no type
-- information here; instead the dark engine itself contains the field name to
-- type mapping. We can get it from newdark with the dump_props_full or
-- dump_props console commands. DarkDB handles this by hardcoding it.
local ObjLink = vstruct.compile('ObjLink', [[
  id:i4
  src:i4
  dst:i4
  flavour:u2
]])

local function supports(tag)
  return tag:match('^L%$') or tag:match('^LD%$')
end

local function loadLink(db, chunk, data)
  -- TODO: read the proplist.txt to get the full link name.
  local tag = chunk.tag:gsub('^.-%$', ''):sub(1, 8)
  for link in ObjLink:records(data) do
    db:merge {
      meta = { id = link.id; type = 'link'; };
      tag = tag;
      src = link.src;
      dst = link.dst;
    }
  end
end

local function loadLinkData(db, chunk, data)
  local tag = chunk.tag:gsub('^.-%$', ''):sub(1, 8)
  if tag == 'MetaProp' then
    -- No support for other LinkData yet, but see DarkDBLinkDefs.h for details
    -- of the other types.
    data = vstruct.cursor(data:sub(5))
    for id,prio in vstruct.records('i4 u4', data, true) do
      db:merge {
        meta = { id = id; type = 'link'; };
        priority = prio;
      }
    end
  end
end

local function load(db, chunk, data)
  if chunk.tag:match('^L%$') then
    return loadLink(db, chunk, data)
  else
    return loadLinkData(db, chunk, data)
  end
end

return {
  supports = supports;
  load = load;
}
