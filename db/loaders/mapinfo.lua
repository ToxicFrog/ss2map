local vstruct = require 'vstruct'

local function supports(tag)
  return tag == 'MAPPARAM'
end

local function load(chunk, data)
  vstruct.readvals('rotatehack:b4', data, chunk)
  return chunk
end

return {
  supports = supports;
  load = load;
}
