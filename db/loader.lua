-- DB file loading code.
-- A DB is made up of one or more "tag files". tagfile.lua contains the code
-- to actually deserialize a tagfile into a sequence of chunks. This file
-- implements the process of peeling apart chunks into individual database
-- objects.

local tagfile = require 'db.tagfile'

local loader = {}

loader.handlers = {
  require 'db.loaders.mapinfo';
  require 'db.loaders.brlist';
  require 'db.loaders.objprop';
  require 'db.loaders.objlink';
}

local function loadChunk(db, chunk, data)
  for _,handler in ipairs(loader.handlers) do
    if handler.supports(chunk.tag) then
      return handler.load(db, chunk, data)
    end
  end
  -- No handler for this chunk; skip it.
end

function loader.load(db, path)
  for chunk,data in tagfile.chunks_from(path) do
    loadChunk(db, chunk, data)
  end
  -- We have now populated the object table, and need to postprocess any properties
  -- and link objects. Properties first:
  for oid,props in pairs(db._properties) do
    local obj = db:object(oid)
    if not obj then
      -- We haven't seen this object. Create a 'generic' object to hold the
      -- properties we've seen associated with this ID; most likely the real
      -- object lives in a chunk we can't decode yet.
      db:insert { meta = { id = oid; type = 'generic'; }; }
      obj = db:object(oid)
    end
    if obj then
      for k,v in pairs(props) do
        obj.meta.props[k] = { key = k; value = v; obj = obj; }
      end
      db._properties[oid] = nil
    end
  end
  -- Now process links. These are first-class objects so we just walk the db
  -- normally.
  for oid,link in db:objects('link') do
    local src,dst = link:deref('src'), link:deref('dst')
    if src and dst then
      src.meta.links[link.tag] = src.meta.links[link.tag] or {}
      src.meta.links[link.tag][oid] = link
      -- TODO: do we also want reverse_links?
    end
  end
end

return loader
