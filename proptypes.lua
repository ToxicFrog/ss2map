-- Hand-crafted deserializers for property types that we can't automatically decode
-- just from the contents of proplist.txt

local vstruct = require 'vstruct'
local ptypes = {}

local function mktype(name, format, pprint)
  if type(pprint) == 'string' then
    local pprint_fmt = pprint
    pprint = function(self, value)
      return pprint_fmt:format(value)
    end
  end
  ptypes[name] = {
    format = format;
    pprint = pprint;
  }
end

local function readNoUnpack(self, data)
  return self.struct:read(data)
end

-- Define all the basic types.
mktype('bool', 'b4', function(self, value) return tostring(value) end)

--mktype('sfloat', 'f2', '%f') -- TODO: 16-bit floats
mktype('float', 'f4', '%f')

mktype('short', 'i2', '%d')
mktype('int', 'i4', '%d')
mktype('int_hex', 'i4', '%x')

mktype('ushort', 'u2', '%u')
mktype('uint', 'u4', '%u')
mktype('uint_hex', 'u4', '%x')

-- Strings may need more work. They generally seem to be c4 null-terminated but
-- I don't know if that's universally true.
mktype('string', 'x4 z', '%s')

mktype('ang', 'p2,15', function(self, value) return '%d°' % (value*180) end)
mktype('rgb', '{ r:u1 g:u1 b:u1 }', function(self, value)
  return '#%02X%02X%02X' % { value.r, value.g, value.b }
end)
mktype('vector', '{ x:f4 y:f4 z:f4 }', function(self, value)
  return '(%.2f, %.2f, %.2f)' % { value.x, value.y, value.z }
end)

ptypes.bitflags = {
  format = 'm4';
  pprint = function(self, value)
    local buf = {}
    for i,bit in ipairs(value) do
      if bit then
        table.insert(buf, self.bits[i] or '[%d]' % i)
      end
    end
    return table.concat(buf, ' | ')
  end;
  parseTail = function(field, tail)
    field.bits = {}
    for name in (tail..','):gmatch('"(.-)",') do
      table.insert(field.bits, name)
    end
  end;
}

ptypes.enum = {
  format = 'u4';
  pprint = function(self, value)
    return self.enum[value] or '[enum: %d]' % value
  end;
  parseTail = function(field, tail)
    field.enum = {}
    local i = 0
    for name in (tail..','):gmatch('"(.-)",') do
      field.enum[i] = name
      i = i+1
    end
  end;
}

--[[
  someday I want to be able to write this as:
  ptypes.Position = aggregate {
    field 'pos' 'vector';
    padding(4);
    field 'rot' 'angvec';
  }
  and have pprint et al work automatically
]]

ptypes.Position = {
  format = 'pos:{ x:f4 y:f4 z:f4 } x4 rot:{ x:pu2,15 y:pu2,15 z:pu2,15 }';
  read = readNoUnpack;
  pprint = function(self, value)
    return '(%.2f,%.2f,%.2f) ϴ (H:%d° P:%d° B:%d°)' %{
      value.pos.x, value.pos.y, value.pos.z, value.rot.z*180, value.rot.y*180, value.rot.x*180
    }
  end;
}

ptypes.sLogData = {
  format = 'Email:m4 Log:m4 Note:m4 Vid:m4';
  read = readNoUnpack;
  pprint = function(self, value, propdef, db)
    local buf = {}
    local strs = 'level%02d' % tonumber(propdef.key:match('%d+$'))
    for type,bits in pairs(value) do
      for i,bit in ipairs(bits) do
        if bit then
          local title = db:string(strs, type..'Name'..i)
          if title then
            table.insert(buf, (title:trim():gsub('\\"', '"'):gsub('\n', '↵')))
          else
            table.insert(buf, '%s:%d' % {type, i})
          end
        end
      end
    end
    return table.concat(buf, ';')
  end;
}

ptypes.unknown = {
  format = '';
  read = function(self, data) return data end;
  pprint = function(self, value)
    return (value:gsub(".", function(c) return ("%02X "):format(c:byte()) end):sub(1,-2))
  end;
}

for k,v in pairs(ptypes) do
  v.struct = v.struct or vstruct.compile(v.format)
  v.parseTail = v.parseTail or function() end
  v.read = v.read or function(self, data)
    return table.unpack(v.struct:read(data))
  end
  v.clone = function(self)
    -- Copy struct over by hand to preserve its metatable
    local other = { struct = self.struct; }
    table.merge(other, self, 'ignore')
    return other
  end;
  -- TODO: autopromote string-only pprints to wrappers around string.interpolate?
end

return ptypes
