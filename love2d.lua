local render = require 'render'

local maps = nil
local map_index = 1

local function hotReload()
  package.loaded.render = nil
  local new_render = require 'render'
  new_render.init(maps[map_index])
  new_render.draw()
  render = new_render
end

function love.keypressed(key)
  if key == 'up' then render.pan(0, -16)
  elseif key == 'down' then render.pan(0, 16)
  elseif key == 'left' then render.pan(-16, 0)
  elseif key == 'right' then render.pan(16, 0)
  elseif key == 'w' then render.zoom(1/8)
  elseif key == 's' then render.zoom(-1/8)
  elseif key == 'q' then love.event.push('quit')
  elseif key == 'r' then
    print('Hot-reloading renderer...')
    local result,err = pcall(hotReload)
    if not result then
      print('Error reloading:', err)
    else
      print('Reload complete!')
    end
  elseif key == 'n' then
    map_index = (map_index % #maps) + 1
    print('Switching to  '..maps[map_index].name)
    render.init(maps[map_index])
  elseif key == 'p' then
    map_index = (map_index - 2) % #maps + 1
    print('Switching to  '..maps[map_index].name)
    render.init(maps[map_index])
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

return function(maplist)
  maps = maplist
  map_index = 1
end
