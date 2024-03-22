-- Loader for gaminfo files.
-- These define object categorization (defcategory) and map information (defmap)
-- used by the map generator.
--
-- See gameinfo/README.md for end user information.

local gameinfo = {}

local function setgamesys(info, path)
  info.gamesys = info.gamedir..'/'..path
end

local function defmap(info, name)
  return function(mapinfo)
    mapinfo.name = name
    if type(mapinfo.files) == 'string' then
      mapinfo.files = { mapinfo.files }
    end
    for i,file in ipairs(mapinfo.files) do
      mapinfo.files[i] = info.gamedir..'/'..file
    end
    table.insert(info.maps, mapinfo)
  end
end

local function defcategory(info, name)
  return function(catinfo)
    catinfo.name = name
    table.insert(info.categories, catinfo)
  end
end

local function loadFiles(env, file, ...)
  if not file then return end
  local fn = assert(loadfile(file))
  setfenv(fn, env)
  fn()
  return loadFiles(env, ...)
end

function gameinfo.load(gamedir, ...)
  local info = { categories = {}; maps = {}; gamedir = gamedir:gsub('/+$', ''); }
  local env = {
    setgamesys = partial(setgamesys, info);
    defmap = partial(defmap, info);
    defcategory = partial(defcategory, info);
  }
  loadFiles(env, ...) -- mutates info
  return info
end

return gameinfo
