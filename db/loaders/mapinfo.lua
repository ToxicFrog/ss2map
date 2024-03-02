local vstruct = require 'vstruct'

local function supports(name)
  return name == 'MAPPARAM'
end

local function load(fd, chunk)
  vstruct.readvals('rotatehack:b4', fd, chunk)
  return chunk
end

return {
  supports = supports;
  load = load;
}
