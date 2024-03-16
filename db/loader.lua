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
  -- Now process links. These are first-class objects so we just walk the db
  -- normally and insert links into their source objects' meta.links field.
  -- If the source or destination doesn't exist we just skip the link.
  -- TODO: handle dangling links better?
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
