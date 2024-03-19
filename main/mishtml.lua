#!/usr/bin/env lua
require 'util'
local DB = require 'db'
local mapgen = require 'mapgen'

flags.registered.gamesys.required = true
flags.registered.proplist.required = true

flags.register('genimages') {
  help = 'generate terrain images. This is very expensive so if the terrain hasn\'t changed consider turning it off.';
  default = true;
}

flags.register('renderscale') {
  help = 'Scale the HTML map to this value';
  type = flags.number;
  default = 4.0;
}

flags.register('html-out') {
  help = 'Directory to write HTML maps to. It must already exist.';
  type = flags.string;
  required = true;
}

flags.register('strings') {
  help = 'Directory containing SS2 .str files to load the localization tables from.';
  type = flags.string;
}

return function(...)
  local result,args = pcall(flags.parse, {...})
  if not result or args.help or #args < 1 then
    if not result then eprintf('%s\n', args) end
    eprintf('Usage: mishtml --html-in=template/dir/ --gamesys=shock2.gam --proplist=proplist.txt [flags] map.mis [map2.mis...]\n')
    eprintf('%s\n', flags.help())
    os.exit(1)
  end

  local db = DB.new()

  print('PROPS', args.proplist)
  db:load_proplist(args.proplist)

  if args.strings then
    print('STRINGS', args.strings)
    for deck=1,9 do
      db:load_strings(args.strings..'/level0'..deck..'.str')
    end
  end

  print('GAMESYS', args.gamesys)
  db:load(args.gamesys)

  local maps = {}
  for i,mis in ipairs(args) do
    print('MAP', mis)
    maps[i] = db:clone()
    maps[i]:load(mis)
    maps[i].name = mis
  end

  mapgen(maps)
  os.exit(0)
end
