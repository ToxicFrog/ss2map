#!/usr/bin/env lua
--[[

  mislist -- lister for mission file contents

]]

require 'util'
local DB = require 'db'

flags.register('help', 'h', '?') {
  help = 'display this text';
}

flags.register('gamesys') {
  help = 'path to gamesys, e.g. shock.gam';
  type = flags.string;
  required = true;
}

flags.register 'propformat' {
  help = 'What format of objprops to use and what proplist to load. These are loaded from proplists/<format>.proplist and proplists/<format>.lua.';
  type = flags.string;
  default = 'ss2';
}

flags.register('objects') {
  help = 'list all objects in the loaded map';
  default = true;
}

flags.register('props') {
  help = 'list all object properties, not just name/position';
}

flags.register('inherited') {
  help = 'when listing object properties, include inherited properties';
}

flags.register('ancestry') {
  help = "print the MetaProp ancestry chain(s) for each object";
}

flags.register('links') {
  help = 'list all object links';
}

flags.register('strings') {
  help = 'Directory containing SS2 .str files to load the localization tables from.';
  type = flags.string;
}

local function typeChain(db, obj, path, strip)
  if path then
    path = table.copy(path)
    table.insert(path, obj:getName())
  else
    path = { '' }
  end
  strip = strip or 0
  local has_parents = false

  for link in obj:getLinks('MetaProp') do
    if has_parents then
      -- inheritance tree splits here
      local prefix_size = #table.concat(path, ' -> ')
      typeChain(db, link:deref(), path, prefix_size)
    else
      typeChain(db, link:deref(), path, strip)
    end
    has_parents = true
  end
  if not has_parents then
    local buf = table.concat(path, ' -> ')
    if strip > 0 then
      printf('    ...%'..(strip-4)..'s%s\n', '...', buf:sub(strip+1))
    else
      printf('   %s\n', buf)
    end
  end
end

local function loadDB(args)
  local db = DB.new()

  -- print('PROPS', args.proplist)
  db:load_proplist(args.propformat)

  if args.strings then
    for deck=1,9 do
      db:load_strings(args.strings..'/level0'..deck..'.str')
    end
  end

  -- print('GAMESYS', args.gamesys)
  db:load(args.gamesys)

  -- print('MIS', args[1])
  db:load(args[1])

  return db
end

local function printObj(db, obj, pos, rot)
  printf('%s @ (%.2f,%.2f,%.2f) ϴ (H:%d° P:%d° B:%d°)\n',
    tostring(obj),
    pos.x, pos.y, pos.z,
    rot.z * 180, rot.y * 180, rot.x * 180)
end

local function listObjs(db, args)
  for id,brush in db:objects('brush') do
    -- Skip everything that isn't an object placement brush.
    if brush.type ~= -3 then goto continue end
    local obj = db:object(brush.primal)
    printObj(db, obj, brush.position, brush.rotation)

    if args.ancestry then
      print('  Ancestry:')
      typeChain(db, obj)
    end

    if args.links then
      print('  Links:')
      for link in obj:getLinks() do
        printf('    %s\n', link)
      end
    end

    if args.props then
      local src = obj
      print('  Properties:')
      for prop in obj:getProperties(args.inherited) do
        if prop.obj ~= src then
          src = prop.obj
          printf('  Properties via %s:\n', src)
        end
        printf('    %-16s: %s\n', prop.key_full, prop:pprint())
      end
    end

    if args.ancestry or args.links or args.props then
      print()
    end

    ::continue::
  end
end

local function main(...)
  local args = flags.parse {...}
  if args.help or #args < 1 then
    print('Usage: mismap [flags] --gamesys=shock.gam map.mis')
    print(flags.help())
    os.exit(1)
  end

  local db = loadDB(args)
  listObjs(db, args)
end

return main(...)
