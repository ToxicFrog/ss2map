local render = require 'render'
local main

local missions = nil
local mis_index = 1

function love.keypressed(key)
  if key == 'up' then render.pan(0, -16)
  elseif key == 'down' then render.pan(0, 16)
  elseif key == 'left' then render.pan(-16, 0)
  elseif key == 'right' then render.pan(16, 0)
  elseif key == 'w' then render.zoom(1/8)
  elseif key == 's' then render.zoom(-1/8)
  elseif key == 'q' then love.event.push('quit')
  elseif key == 'n' then
    mis_index = (mis_index % #missions) + 1
    print('Switching to mission '..mis_index)
    render.init(missions[mis_index])
  elseif key == 'p' then
    mis_index = (mis_index - 2) % #missions + 1
    print('Switching to mission '..mis_index)
    render.init(missions[mis_index])
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
  missions = main(table.unpack(argv))
  love.window.setMode(1280, 960)
  render.init(missions[mis_index])
end

return function(f)
  main = f
end
