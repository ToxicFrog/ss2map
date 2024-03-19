#!/usr/bin/env lua
require 'util'
local setup = require 'love2d'
local render = require 'render'
local DB = require 'db'

return function(...)
  local result,args = pcall(flags.parse, {...})
  if not result or args.help or #args < 1 then
    if not result then eprintf('%s\n', args) end
    eprintf('Usage: misview [--gamesys=shock2.gam] [--proplist=proplist.txt] map.mis [map2.mis...]\n')
    eprintf('%s\n', flags.help())
    os.exit(1)
  end

  local db = DB.new()

  print('PROPS', args.propformat)
  db:load_proplist(args.propformat)

  if args.gamesys then
    print('GAMESYS', args.gamesys)
    db:load(args.gamesys)
  else
    print('WARNING: no --gamesys specified, archetype data will be unavailable')
  end

  local maps = {}
  for i,mis in ipairs(args) do
    print('MAP', mis)
    maps[i] = db:clone()
    maps[i]:load(mis)
    maps[i].name = mis
  end

  setup(maps)
  render.init(maps[1])
end
