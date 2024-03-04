-- Loaders for various chunk types.

local LOADERS = {
  require 'db.loaders.mapinfo';
  require 'db.loaders.brlist';
  require 'db.loaders.objprop';
}

return function(fd, chunk)
  local raw = fd:read(chunk.toc.size)
  for _,loader in ipairs(LOADERS) do
    if loader.supports(chunk.meta.tag) then
      return loader.load(chunk, raw)
    end
  end
  -- No loaders matched, so just save the raw data.
  chunk.raw = raw
  return chunk
end
