#!/usr/bin/env lua
require 'util'
local DB = require 'db'
local mapgen = require 'mapgen'

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

flags.register('gamedir') {
  help = 'Path to the directory containing the gamesys and mission files referenced by the gameinfo.';
  type = flags.string;
  required = true;
}

flags.register('gameinfo') {
  help = 'Comma-separated list of gameinfo scripts to load.';
  type = flags.listOf(flags.string);
  required = true;
}

return function(...)
  local result,args = pcall(flags.parse, {...})
  if not result or args.help then
    if not result then eprintf('%s\n', args) end
    eprintf('Usage: mishtml --gamedir=game/ --propformat=game --gameinfo=gameinfo/game.lua --html-out=maps [flags] [map.mis...]\n')
    eprintf('%s\n', flags.help())
    os.exit(1)
  end

  local db = DB.new()

  print('PROPS', args.propformat)
  db:load_proplist(args.propformat)

  if args.strings then
    print('STRINGS', args.strings)
    for deck=1,9 do
      db:load_strings(args.strings..'/level0'..deck..'.str')
    end
  end

  local info = require('gameinfo').load(args.gamedir, unpack(args.gameinfo))

  -- --gamesys and positional args override the gameinfo scripts
  if args.gamesys then info.gamesys = args.gamesys end
  if #args > 0 then
    info.maps = {}
    for i,file in ipairs(args) do
      table.insert(info.maps, {
        name = file:match('[^/]+$');
        short = tostring(i-1);
        files = { file };
      })
    end
  end

  print('GAMESYS', info.gamesys)
  db:load(info.gamesys)

  for i,map in ipairs(info.maps) do
    print('MAP', map.files[1])
    map.db = db:clone()
    map.db:load(map.files[1])
  end

  mapgen(info)
  os.exit(0)
end
