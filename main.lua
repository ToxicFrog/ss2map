#!/usr/bin/env lua
require 'util'
local vstruct = require 'vstruct'
local tagfile = require 'db.tagfile'

flags.register('help', 'h', '?') {
  help = 'display this text';
}

flags.register('gamesys') {
  help = 'path to gamesys, e.g. shock.gam';
  type = flags.string;
}

flags.register('objects') {
  help = 'list all objects in the loaded map';
}

flags.register('props') {
  help = 'list all object properties, not just name/position';
}

flags.register('inherited') {
  help = 'when listing object properties, include inherited properties';
}

local function listobjs(mis, props, inherited)
  for id,brush in pairs(mis.chunks.BRLIST.by_type[-3]) do
    local pos = brush.position
    local name = mis:getProp(brush.primal, 'SymName', true)
    printf('[%08x] %s @ (%f,%f,%f)\n',
        brush.primal, name, pos.x, pos.y, pos.z)
    if props then
      for k,v,inherited in mis:propPairs(brush.primal, inherited) do
        printf('  %s %-16s %s\n', inherited and '+' or ' ', k..':', v)
      end
    end
  end
end

local function main(...)
  local args = flags.parse {...}
  if args.help or #args < 1 then
    print('Usage: mismap [flags] [--gamesys=shock.gam] map.mis')
    print(flags.help())
    os.exit(1)
  end

  local gam; if args.gamesys then gam = tagfile(args.gamesys) end
  local mis = tagfile(args[1], gam)

  if args.objects then
    listobjs(mis, args.props, args.inherited)
  end

  return mis
end

if love then
  require 'love2d' (main)
else
  return main(...)
end
