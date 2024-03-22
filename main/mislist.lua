#!/usr/bin/env lua
--[[

  mislist -- lister for mission file contents

]]

require 'util'
local DB = require 'db'
local libmislist = require 'libmislist'

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

-- TODO: switch between listing everything in the objmap vs. listing all object
-- brushes
-- flags.register('objects') {
--   help = 'list all objects in the loaded map';
--   default = true;
-- }

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

local function main(...)
  local args = flags.parse {...}
  if args.help or #args < 1 then
    print('Usage: mismap [flags] --gamesys=shock.gam map.mis')
    print(flags.help())
    os.exit(1)
  end

  local db = loadDB(args)
  libmislist.listObjects(db, args)
end

return main(...)
