-- High-level darkdb API.
--
-- Fundamentally, a database is a map of IDs to objects. Objects have the skeleton:
-- {
--   meta = {
--     -- primary key; is usually negative for gamesys objects and positive for map objects
--     id = (int);
--     -- object type; we mostly care about 'brush', 'property', and 'link'
--     type = (string);
--     -- object source; path to the tagfile it was defined in
--     src = (string);
--     -- Object properties defined from P$ chunks; does not include inherited props.
--     props = {
--       name = value;
--     };
--     -- Inter-object links defined from L$ and LD$ chunks.
--     links = {
--       type = { { id, src, dst, priority }, ... };
--     };
--   };
--   ...data fields...
-- }
--
-- When using the db, one first creates a db, then loads one or more files into
-- it, typically starting with the gamesys. The loading process reads all the
-- chunks in the file and, for each one that has a loader, invokes the loader,
-- which is responsible for adding or updating objects in the database. A typical
-- chunk will contain multiple objects, and in some cases one object will be
-- smeared across multiple chunks (e.g. reconstructing a link requires both its
-- L$ and LD$ entries).
--
-- Once all chunks are loaded, the database library postprocesses the objects by
-- reading link and property objects to build the meta.links and meta.props fields
-- for each object.
--
-- When using the db, you will usually call db:get(id) to get individual objects,
-- or db:pairs(type) to iterate over all objects of a given type.
local loader = require 'db.loader'

local db = {}
db.__index = db

-- Create a new, empty database.
function db.new()
  local self = {
    -- map from ID to object
    _objects = {};
    -- map of type => ID => object
    _objects_by_type = {};
    -- properties set during the loading process, which will be applied to the
    -- actual objects at the end of loading
    -- map of ID => key => value
    _properties = {};
  }
  return setmetatable(self, db)
end

-- Create a deep copy of this database.
-- Useful for situations where you want to load the gamesys once and then
-- load multiple different mission files in isolation using it.
function db:clone()
  local clone = table.copy(self)
  return setmetatable(clone, db)
end

-- Load the given file into the database.
function db:load(file)
  loader.load(self, file)
end

-- Get a single object from the database. Throws if there is no object with the
-- given ID.
function db:object(id)
  if self._objects[id] then
    return self:wrap(self._objects[id])
  else
    return nil,'no object with id '..id
  end
end

local object = require 'db.object'
local link = require 'db.link'
-- Wrap an object with a metatable that supplies suitable convenience methods.
-- Automatically chooses the correct wrapper based on the object's type.
function db:wrap(obj)
  if obj.meta.type == 'link' then
    return link.wrap(obj)
  else
    return object.wrap(obj)
  end
end

-- Iterate over all objects of a given type. If type is omitted, iterates over
-- all objects in the db.
function db:objects(type)
  local t = type and (self._objects_by_type[type] or {}) or self._objects
  return coroutine.wrap(function()
    for k,v in pairs(t) do
      coroutine.yield(k, self:wrap(v))
    end
  end)
end

-- Setter functions below are generally used by loaders when deserializing chunks
-- into the database.

-- Insert an object into the database. meta.id and meta.type fields are required.
-- If an object of the given name already exists, throws.
function db:insert(obj)
  assert(obj.meta.id and obj.meta.type, 'db:insert(): meta.id and meta.type fields are required')
  assert(not self._objects[obj.meta.id], 'db:insert(): object '..obj.meta.id..' already exists')
  obj.meta.db = self
  obj.meta.props = {}
  obj.meta.links = {}
  self._objects[obj.meta.id] = obj
  self._objects_by_type[obj.meta.type] = self._objects_by_type[obj.meta.type] or {}
  self._objects_by_type[obj.meta.type][obj.meta.id] = obj
end

-- Update an object already in the database. meta.id is required. Data fields
-- will be merged into the existing object. Throws if there is no such object
-- to update.
function db:update(obj)
  local oid = obj.meta.id
  assert(oid, 'db:update(): meta.id field is required')
  assertf(self._objects[oid], 'db:update(%d): no object with this id', oid)
  if obj.meta.type then
    assertf(self._objects[oid].meta.type == obj.meta.type,
      'db:update(%d): mismatched types: %s != %s',
      oid, self._objects[oid].meta.type, obj.meta.type)
  end

  -- local function merger(k, v1, v2)
  --   if k == 'meta' then return v1 end
  --   return table.mergeDupes(k, v1, v2)
  -- end

  table.mergeWith(self._objects[obj.meta.id], obj, table.mergeDupes)
end

-- Set a property on an object.
-- The property won't actually be available until DB loading is complete.
function db:setProp(oid, key, value)
  self._properties[oid] = self._properties[oid] or {}
  self._properties[oid][key] = value
end

-- Create or update an object. meta.id and meta.type are required. Behaves like
-- update() if the object already exists and like insert() if it does not.
function db:merge(obj)
  if not self._objects[obj.meta.id] then
    return self:insert(obj)
  else
    return self:update(obj)
  end
end

return db
