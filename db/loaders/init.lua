-- Loaders for various chunk types.

local LOADERS = {
  require 'db.loaders.mapinfo';
  -- require 'db.loaders.brlist';
}

return function(fd, chunk)
  for _,loader in ipairs(LOADERS) do
    if loader.supports(chunk.meta.tag) then
      return loader.load(fd, chunk)
    end
  end
  -- No loaders matched, so just read in the raw data buffer.
  chunk.raw = fd:read(chunk.toc.size)
  return chunk
end
