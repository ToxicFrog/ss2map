-- Dark Engine tag files (.MIS, .GAM, etc)
-- These contain tagged data blocks, usually (always?) no more than one of each
-- type. The game db is made of multiple overlaid tagfiles:
-- gamesys -> mission -> save.
-- Usually you won't interact with this directly, you'll use db.lua to load
-- one or more tagfiles and query that.

local vstruct = require 'vstruct'
local loadChunk = require 'db.loaders'

local tagfile = {}
tagfile.__index = tagfile

function tagfile:__tostring()
  return string.format('tagfile[%s]', self.path or '(empty)')
end

local TagFileIndex = vstruct.compile('TagFileIndex', [[
  -- start of file header
  <
  offset:u4
  x8
  comment:z256
  > magic:u4 < -- 0xDEADBEEF

  -- actual chunk index
  @#offset
  n:u4
  #n * {
    tag:z12
    offset:u4
    size:u4
  }
]])

local ChunkHeader = vstruct.compile('ChunkHeader', [[
  tag:z12
  major:u4
  minor:u4
  zero:u4
]])

function tagfile:load(path)
  local fd = assert(io.open(path, 'rb'))
  self.path = path
  TagFileIndex:read(fd, self.toc)
  for _,entry in ipairs(self.toc) do
    fd:seek('set', entry.offset)
    local chunk = {
      toc = entry;
      meta = ChunkHeader:read(fd);
    }
    if entry.size > 0 then
      loadChunk(self, fd, chunk)
    end
    self.chunks[chunk.meta.tag] = chunk
  end
end

function tagfile:addLink(src, type, dst)
  self.links[src] = self.links[src] or {}
  self.links[src][type] = dst
end

function tagfile:derefLink(src, type)
  local links = self.links[src]
  if links and links[type] then return links[type] end
  if self.parent then return self.parent:derefLink(src, type) end
end

function tagfile:addProp(id, prop, value)
  self.props[id] = self.props[id] or {}
  self.props[id][prop] = value
end

-- Get a named property. If include_metaprops is set, also searches the object's
-- MetaProp link to get the default value.
function tagfile:getProp(id, name, include_metaprops)
  local props = self.props[id]
  local val = props and props[name]
  if val ~= nil then return val end
  val = self.parent and self.parent:getProp(id, name, include_metaprops)
  if val ~= nil then return val end
  if include_metaprops then
    local base = self:derefLink(id, 'MetaProp')
    if base then return self:getProp(base, name, true) end
  end
  return nil
end

-- Return a table containing all of the properties of the given object.
function tagfile:getPropTable(id, include_metaprops)
  local props = {}
  for k,v in self:props(id, include_metaprops) do
    props[k] = v
  end
  return props
end

-- Returns an iterator over all properties for the object.
-- For each property, yields name, value, inherited; the latter is true if the
-- property was inherited from the metaprops.
function tagfile:propPairs(id, include_metaprops)
  local seen = {}
  return coroutine.wrap(function()
    for k,v in pairs(self.props[id] or {}) do
      seen[k] = true
      coroutine.yield(k, v, false)
    end
    if self.parent then
      for k,v,inherited in self.parent:propPairs(id, include_metaprops) do
        if not seen[k] then
          seen[k] = true
          coroutine.yield(k, v, inherited)
        end
      end
    end
    local base = self:derefLink(id, 'MetaProp')
    if not base or not include_metaprops then return end
    for k,v in self:propPairs(base, true) do
      if not seen[k] then
        seen[k] = true
        coroutine.yield(k, v, true)
      end
  end
  end)
end

-- Return the MetaProp table for a given object by looking up its metaprop link.
function tagfile:getMetaProps(id)
  local links = self.links[id]
  if links and links.MetaProp then
    return self:getProps(links.MetaProp)
  end
end

-- Get a table containing all of the properties on an object.
-- We eagerly merge the properties so that callers can use ipairs and stuff.
function tagfile:getProps(id)
  -- Do we even know about this object? If not, delegate to the parent if we have one.
  local props = self.props[id]
  if not props then
    return self.parent and self.parent:getProps(id)
  end

  -- Initially populate with the MetaProps.
  local obj = {}
  local mp = self:getMetaProps(id)
  for k,v in pairs(mp or {}) do
    props[k] = v
  end
  for k,v in pairs(props) do
    obj[k] = v
  end
  return obj
end

return function(path, parent)
  local self = {
    parent = parent; -- parent tagfile to look up properties/links in
    toc = {};    -- linear list of TOC entries
    chunks = {}; -- tag to chunk data structure map
    props = {};  -- object ID to property name to property value map
    links = {}; -- object ID to link name to target object map
  }
  setmetatable(self, tagfile)
  self:load(path)
  return self
end
