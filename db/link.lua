-- Wrapper API for Dark Engine database links.
--
-- Links are first-class objects with src, dst, and flavour fields, and possibly
-- additional fields depending on the link type.
--
-- This wrapper provides some convenience methods on them to make them easier
-- to use than using the generic Object API.

local object = require 'db.object'
local link = table.copy(object)
link.__index = link

function link:__tostring()
  local function nameOf(oid)
    local obj = self.meta.db:object(oid)
    if not obj then
      return '(%d)' % oid
    else
      return tostring(obj)
    end
  end
  return string.format('Link[%s] (%d): %s -> %s',
    self.tag, self.meta.id, nameOf(self.src), nameOf(self.dst))
end

function link.wrap(obj)
  return setmetatable(obj, link)
end

-- Dereference the link and return the object pointed to. `dir` can be either
-- `src` or `dst` and defaults to `dst`.
function link:deref(dir)
  dir = dir or 'dst'
  assert(dir == 'src' or dir == 'dst', 'link:deref(): dir must be either "src" or "dst"')
  return self.meta.db:object(self[dir])
end

return link