-- Dark Engine tag files (.MIS, .GAM, etc)
-- These contain tagged data blocks, usually (always?) no more than one of each
-- type. The game db is made of multiple overlaid tagfiles:
-- gamesys -> mission -> save.
-- Usually you won't interact with this directly, you'll use db.lua to load
-- one or more tagfiles and query that.

-- TODO: the whole tagfile/db interface needs a complete redesign to give us
-- a proper object map, support duplicate links of the same name, etc.

local vstruct = require 'vstruct'

local TagFileIndex = vstruct.compile('TagFileIndex', [[
  -- start of file header
  <
  offset:u4
  x8
  comment:z256
  > magic:u4 < -- 0xDEADBEEF

  -- actual chunk index
  @#offset
  n:u4
  #n * {
    tag:z12
    offset:u4
    size:u4
  }
]])

local ChunkHeader = vstruct.compile('ChunkHeader', [[
  tag:z12
  major:u4
  minor:u4
  zero:u4
]])

local tagfile = {}

function tagfile.chunks_from(path)
  local fd = assert(io.open(path, 'rb'))
  local toc = TagFileIndex:read(fd)

  return coroutine.wrap(function()
    for _,entry in ipairs(toc) do
      fd:seek('set', entry.offset)
      ChunkHeader:read(fd, entry)
      if entry.size > 0 then
        local data = fd:read(entry.size)
        coroutine.yield(entry, data)
      end
    end
  end)
end

return tagfile
