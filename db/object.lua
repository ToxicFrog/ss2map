-- Wrapper API for Dark Engine database objects.
--
-- In general, you can access object fields as normal table fields, and object
-- metadata (id, type, links, props) via the .meta subtable.
--
-- This wrapper adds a number of convenience functions for things like link
-- dereferencing, MetaProp-aware property reading, and whatnot.

local object = {}
object.__index = object

function object:__tostring()
  return string.format('%s (%d)', self:getName(), self.meta.id)
end

function object.wrap(obj)
  return setmetatable(obj, object)
end

-- Return the object's human-readable name.
-- This is, in descending priority:
-- - (TODO) the name from strings/objshort.str
-- - the name from OBJ_MAP
-- - the SymName property
-- if none of these are available it falls back to the object type.
function object:getName()
  return self.name
    or self:getProperty('SymName')
    or '[anonymous %s]' % self.meta.type
end

function object:setProperty(key, prop)
  prop = table.copy(prop)
  prop.obj = self;
  self.meta.props[key] = prop
end

-- Get a named property on the object. Returns the underlying value of the property.
-- If `inherit` is true, will search along MetaProp links if the
-- property isn't found in the leaf object. Defaults to true.
function object:getProperty(name, inherit)
  if inherit == nil then inherit = true end

  if self.meta.props[name] then
    return self.meta.props[name].value
  elseif inherit then
    for link in self:getLinks('MetaProp') do
      local prop = link:deref():getProperty(name, true)
      if prop then return prop end
    end
  end
  return nil
end

-- Return an iterator over all properties on the object. If inherit is true,
-- will also iterate over all parent properties via the MetaProp links. The
-- caller can differentiate by reading the obj field of the returned property
-- objects.
-- If a property exists in multiple places in the inheritance chain, only the
-- one that actually holds the final value will appear in the iteration.
function object:getProperties(inherit)
  local seen = {}
  return coroutine.wrap(function()
    for k,v in pairs(self.meta.props) do
      seen[k] = true
      coroutine.yield(v)
    end
    if not inherit then return end
    for link in self:getLinks('MetaProp') do
      for prop in link:deref():getProperties(true) do
        if not seen[prop.key] then
          seen[prop.key] = true
          coroutine.yield(prop)
        end
      end
    end
  end)
end

-- Return an iterator over all links of the given type.
-- Yields the underlying link objects: tables with fields src, dst, type, and
-- priority.
-- If type is not specified, iterates over all outgoing links.
-- Link types are iterated in unspecified order, but within a type, links are
-- iterated in descending priority order.
function object:getLinks(type)
  if type then
    return coroutine.wrap(function()
      for _,ln in pairs(self.meta.links[type] or {}) do
        coroutine.yield(self.meta.db:wrap(ln))
      end
    end)
  else
    return coroutine.wrap(function()
      for type in pairs(self.meta.links) do
        for ln in self:getLinks(type) do
          coroutine.yield(self.meta.db:wrap(ln))
        end
      end
    end)
  end
end

return object