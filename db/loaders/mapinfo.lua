local vstruct = require 'vstruct'

local function supports(tag)
  return tag == 'MAPPARAM'
end

local function load(db, chunk, data)
  -- TODO: setFlag
  -- db:setFlag('rotatehack', vstruct.readvals('b4', data))
end

return {
  supports = supports;
  load = load;
}
