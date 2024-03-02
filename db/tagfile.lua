-- Dark Engine tag files (.MIS, .GAM, etc)
-- These contain tagged data blocks, usually (always?) no more than one of each
-- type. The game db is made of multiple overlaid tagfiles:
-- gamesys -> mission -> save.
-- Usually you won't interact with this directly, you'll use db.lua to load
-- one or more tagfiles and query that.

local vstruct = require 'vstruct'
local loadChunk = require 'db.loaders'

local tagfile = {}
tagfile.__index = tagfile

function tagfile:__tostring()
  return string.format('tagfile[%s]', self.path or '(empty)')
end

local toc = vstruct.compile('TagFileIndex', [[
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

local chunk_header = vstruct.compile('TagChunkHeader', [[
  tag:z12
  major:u4
  minor:u4
  zero:u4
]])

function tagfile:load(path)
  local fd = assert(io.open(path, 'rb'))
  self.path = path
  toc:read(fd, self.toc)
  for _,entry in ipairs(self.toc) do
    fd:seek('set', entry.offset)
    local chunk = {
      toc = entry;
      meta = chunk_header:read(fd);
    }
    if entry.size > 0 then
      loadChunk(fd, chunk)
    end
    self.chunks[chunk.meta.tag] = chunk
  end
end

return function(path)
  local self = {
    toc = {};
    chunks = {};
  }
  setmetatable(self, tagfile)
  self:load(path)
  return self
end
