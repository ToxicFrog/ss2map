require 'util'

-- common flags
flags.register('help', 'h', '?') {
  help = 'display this text';
}

flags.register('gamesys') {
  help = 'path to gamesys, e.g. shock.gam';
  type = flags.string;
}

flags.register 'propformat' {
  help = 'What format of objprops to use and what proplist to load. These are loaded from proplists/<format>.proplist and proplists/<format>.lua.';
  type = flags.string;
  default = 'ss2';
}

-- currently disabled, may be reinstated later
-- flags.register('rotatehack') {
--   help = 'Rotate the view of the map so it matches up with the in-game compass and automap rather than with ShockEd'
-- }

local function main(...)
  local mainlib = os.getenv('MISMAP_MAIN')
  if not mainlib then
    eprintf('Error: no MISMAP_MAIN environment variable -- please run via one of the wrapper scripts\n')
    os.exit(1)
  end
  local loading = love.graphics.newImage("res/loading.png")
  local w,h = love.window.getMode()
  local iw,ih = loading:getDimensions()
  love.graphics.push()
  love.graphics.translate(w/2 - iw/2, h/2 - ih/2)
  love.graphics.draw(loading, 0, 0)
  love.graphics.pop()
  love.graphics.present()

  return require(mainlib)(...)
end

function love.load(argv)
  main(table.unpack(argv))
end
