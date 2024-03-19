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
local proplist = require 'db.proplist'
local strings = require 'db.strings'

local db = {}
db.__index = db

-- Create a new, empty database.
function db.new()
  local self = {
    -- map meta.type => meta.id => object
    _objects = {};
    -- parsed property list and property deserializer/prettyprinter interface
    _plist = nil;
    -- string tables
    _strings = {};
  }
  return setmetatable(self, db)
end

-- Create a deep copy of this database.
-- Useful for situations where you want to load the gamesys once and then
-- load multiple different mission files in isolation using it.
function db:clone()
  local clone = db.new()
  clone._plist = self._plist -- read-only, so safe to share
  clone._strings = self._strings -- likewise
  -- in an ideal world individual objects would be readonly, but it turns out
  -- that, e.g., you can load archetype -1 from the gamesys and then rename it
  -- in the OBJ_MAP of earth.mis and now everything is horrible.
  clone._objects = table.copy(self._objects)
  return clone
end

-- Load the given file into the database.
function db:load(file)
  loader.load(self, file)
end

function db:load_proplist(file)
  self._plist = proplist.load(file)
end

function db:load_strings(file)
  local name = file:match('([^/]+)%.str$')
  assert(name, "unable to determine basename for string table "..file)
  self._strings[name] = strings.load(file)
end

local function byType(db, type)
  if not db._objects[type] then
    db._objects[type] = {}
  end
  return db._objects[type]
end

-- Get a string from the localization database.
-- If the file is not loaded or no such string exists in it, returns nil.
-- File should be the str filename without path or extension, e.g.
-- db:string('objshort', 'BigBomb') => 'Sympathetic Resonator'
function db:string(file, key)
  return self._strings[file] and self._strings[file][key]
end

-- Get a single object from the database. Throws if there is no object with the
-- given ID. The object type defaults to 'entity' if unspecified.
function db:object(id, type)
  type = type or 'entity'
  local obj = byType(self, type)[id]
  if obj then
    return self:wrap(obj)
  else
    return nil,'no '..type..' with id '..id
  end
end

local object = require 'db.object'
local link = require 'db.link'
-- Wrap an object with a metatable that supplies suitable convenience methods.
-- Automatically chooses the correct wrapper based on the object's type.
function db:wrap(obj)
  if obj.meta.type == 'link' then
    return link.wrap(obj, self)
  else
    return object.wrap(obj, self)
  end
end

-- Iterate over all objects of a given type. If type is omitted, iterates over
-- all objects in the db. Note that in the latter case you may get duplicate IDs,
-- as IDs are not unique across object types -- look at obj.meta.type if you
-- need to differentiate different types.
function db:objects(type)
  if type then
    return coroutine.wrap(function()
      for k,v in pairs(byType(self, type)) do
        coroutine.yield(k, self:wrap(v))
      end
    end)
  else
    return coroutine.wrap(function()
      for _,objs in pairs(self._objects) do
        for k,v in pairs(objs) do
          coroutine.yield(k, self:wrap(v))
        end
      end
    end)
  end
end

-- Setter functions below are generally used by loaders when deserializing chunks
-- into the database.

-- Insert an object into the database. meta.id and meta.type fields are required.
-- If an object of the given name already exists, throws.
function db:insert(obj)
  local oid,otype = obj.meta.id, obj.meta.type
  assert(oid, 'db:insert(): meta.id field is required')
  assertf(otype, 'db:insert(%d): meta.type field is required', oid)
  self._objects[otype] = self._objects[otype] or {}
  assert(not self._objects[otype][oid], 'db:insert(%d): a %s object with this id already exists', oid, otype)
  obj.meta.props = {}
  obj.meta.links = {}
  self._objects[otype][oid] = obj
end

-- Update an object already in the database. meta.id and meta.type are required.
-- Data fields will be merged into the existing object. Throws if there is no
-- such object to update.
function db:update(obj)
  local oid,otype = obj.meta.id, obj.meta.type
  assert(oid, 'db:update(): meta.id field is required')
  assertf(otype, 'db:update(%d): meta.type field is required', oid)
  local old = assert(self:object(oid, otype))
  assertf(old.meta.type == obj.meta.type,
    'db:update(%d): mismatched types: %s != %s',
    oid, old.meta.type, obj.meta.type)

  table.mergeWith(old, obj, table.mergeDupes)
end

-- Create or update an object. meta.id and meta.type are required. Behaves like
-- update() if the object already exists and like insert() if it does not.
function db:merge(obj)
  local oid,otype = obj.meta.id, obj.meta.type
  assert(oid, 'db:merge(): meta.id field is required')
  assertf(otype, 'db:merge(%d): meta.type field is required', oid)
  if self:object(oid, otype) then
    return self:update(obj)
  else
    return self:insert(obj)
  end
end

return db
