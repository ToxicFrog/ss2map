-- Wrapper API for Dark Engine database links.
--
-- Links are first-class objects with src, dst, and flavour fields, and possibly
-- additional fields depending on the link type.
--
-- This wrapper provides some convenience methods on them to make them easier
-- to use than using the generic Object API.

local object = require 'db.object'
local link = table.copy(object)

function link:__tostring()
  local function nameOf(oid)
    local obj = getmetatable(self).__db:object(oid)
    if not obj then
      return '(%d)' % oid
    else
      return tostring(obj)
    end
  end
  return string.format('Link[%s] (%d): %s -> %s',
    self.tag, self.meta.id, nameOf(self.src), nameOf(self.dst))
end

function link.wrap(obj, db)
  return setmetatable(obj, {
    __index = link;
    __tostring = link.__tostring;
    __db = db;
  })
end

-- Dereference the link and return the object pointed to. `dir` can be either
-- `src` or `dst` and defaults to `dst`.
function link:deref(dir)
  dir = dir or 'dst'
  assert(dir == 'src' or dir == 'dst', 'link:deref(): dir must be either "src" or "dst"')
  if not self[dir] then return nil end
  return getmetatable(self).__db:object(self[dir])
end

return link
