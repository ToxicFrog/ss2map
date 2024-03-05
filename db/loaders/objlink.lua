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
  return tag:match('^L%$')
end

local function load(self, chunk, data)
  -- TODO: read the proplist.txt to get the full link name.
  chunk.link_name = chunk.meta.tag:sub(3,-1)
  chunk.links = {}
  for link in ObjLink:records(data) do
    -- per-chunk maps gives us link type -> src -> dst
    chunk.links[link.src] = link.dst
    -- also update the per-file src -> type -> dst map
    self:addLink(link.src, chunk.link_name, link.dst)
  end
  return chunk
end

return {
  supports = supports;
  load = load;
}
