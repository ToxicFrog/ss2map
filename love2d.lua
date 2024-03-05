local render = require 'render'
local main

function love.keypressed(key)
  if key == 'up' then render.pan(0, -16)
  elseif key == 'down' then render.pan(0, 16)
  elseif key == 'left' then render.pan(-16, 0)
  elseif key == 'right' then render.pan(16, 0)
  elseif key == 'w' then render.zoom(1/8)
  elseif key == 's' then render.zoom(-1/8)
  end
end

function love.mousemoved(x, y, dx, dy)
  if love.mouse.isDown(1) then
    render.pan(dx, dy)
  end
end

function love.draw()
  render.draw()
end

function love.load(argv)
  local mis = main(table.unpack(argv))
  love.window.setMode(1280, 960)
  render.init(mis)
end

return function(f)
  main = f
end
