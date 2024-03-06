-- Library for reading the proplist.txt
-- There are two versions, "basic" and "full"

-- Basic version is line-oriented:
-- ObjProp "Transient" : BOOL // flags 0x0001  editor name: "Object System: Transient"
-- Starts with ObjProp, Link, or Effect. String after that is the name; only the
-- first nine characters are used in the chunk header. Not sure what "flags" are
-- for, but the editor name is the human-readable name for it.
-- Types can be BOOL, int, string, float, but also in-house structs like
-- sStatsDesc or enums like eSlayResult.

-- Full version includes more data:
--[[
ObjProp "BaseStatsDesc"  // type sStatsDesc   , flags 0x000, editor name: "Player: Base Stats"
{
  "STR": int
  "END" int
  "PSI: int
  ...and so on...
}
]]
-- Which means it gives us the actual internal structure, and a type name to
-- structure mapping!
-- Structs with only one field will usually have it named "", but some of them
-- will give it a name.
-- Enums will have something that looks like:
-- "Effect" : enum // enums: "Normal", "No Effect", "Terminate", "Destroy"
-- And bitmasks:
-- "" : bitflags // flags: "Once Grunt Organ", "Spore Organ", "Midwife Organ", ....

-- We can automatically convert these into vstruct structure definitions!
-- And then generate the vstruct chunk types for each objprop chunk on the fly.
-- SICK.
-- N.b. for the ones that have field names, they sometimes have spaces and
-- punctuation in them, vstruct only supports lua identifiers, so we need to
-- munge them.

local vstruct = require 'vstruct'
local proplist = {}
local PROPDEFS = {}

function proplist.load(file)
  return proplist.parse(io.open(file, 'rb'):read('*a'))
end

local formats = {
  ang = 'p2,15'; -- assuming it's the same as in brushes...
  bitflags = 'u4';
  bool = 'b4';
  enum = 'u4';
  float = 'f4';
  int = 'i4';
  int_hex = 'i4';
  rgb = '{ r:u1 g:u1 b:u1 }';
  sfloat = 'u2'; -- TODO: 16-bit floats
  short = 'i2';
  -- strings are a mess; some are c4, some are c4 null terminated, some are z with a fixed buffer size
  string = 'x4 z';
  uint = 'u4';
  uint_hex = 'u4';
  ushort = 'u2';
  vector = '{ x:f4 y:f4 z:f4 }';
}

local function mungeKey(key)
  return key:gsub('%W+', '_'):gsub('_+$', ''):gsub('^_+', ''):gsub('^(%d)', '_%1')
end

local function parseBody(self, body)
  local buf = {}
  for name,type,tail in body:gmatch('"(.-)"%s*:%s*(%S+)(.-)\n') do
    table.insert(buf, {key = name, format = assert(formats[type], type)})
  end
  if #buf == 1 then
    -- only one field!
    self.format = vstruct.compile(buf[1].format)
    self.unpack = true
  else
    -- Turns out the field list in proplist.txt is not guaranteed to be in the
    -- correct order, RIP.
    -- For now just pass through the data.
    -- for i,field in ipairs(buf) do
    --   buf[i] = mungeKey(field.key)..':'..field.format
    -- end
    -- self.format = vstruct.compile(table.concat(buf, ' '))
  end
end

local propdef_matcher = string.gsub(
  'ObjProp "(.-)" // type (%S+) , flags 0x(%x+)(.-)(%b{})',
  ' ', '%%s+')

function proplist.parse(buf)
  PROPDEFS = {}
  for name,ctype,flags,tail,body in buf:gmatch(propdef_matcher) do
    local propdef = {
      name = name;
      ctype = ctype;
      flags = tonumber(flags, 16); -- TODO: figure out what all the flags mean
      editor_name = tail:match('editor name: "(.-)"');
    }
    parseBody(propdef, body)
    PROPDEFS[name] = propdef
    PROPDEFS[name:sub(1,9)] = propdef -- tagfiles only store the first nine bytes of the name
  end
end

function proplist.read(name, buf)
  local prop = PROPDEFS[name]
  if not prop or not prop.format then return '[unknown: '..#buf..' bytes]' end
  if prop.unpack then
    return table.unpack(prop.format:read(buf))
  else
    return prop.format:read(buf)
  end
end

return proplist
