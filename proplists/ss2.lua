-- Use the common proptypes as a basis.
local ptypes = require 'proplists.common'

-- Information about both locks (KeyDst) and keys (KeySrc).
ptypes.sKeyInfo = {
  -- On-disk format, as a vstruct format. You can provide either this or a read()
  -- function.
  format = '{ master:b1 regions:m4 lock:u1 }';
  -- Optional; this is used to parse the comments attached to enum and bitflag
  -- fields. In this case, only one field in sKeyInfo has these comments, so we
  -- just watch for it and then outsource the parsing to the common bitflags type.
  parseTail = function(self, name, type, tail)
    if name == 'RegionID' then
      ptypes.bitflags.parseTail(self, name, type, tail)
    end
  end;
  -- Function for producing a human-readable version of the property value.
  -- Self is going to be the ptype definition, value is the property value, and
  -- propdef and db are the enclosing tagfile and database.
  pprint = function(self, value, propdef, db)
    local buf = {}
    table.insert(buf, (ptypes.bitflags.pprint(self, value.regions, propdef, db):gsub(' | ', '/')))
    table.insert(buf, '#%d' % value.lock)
    if value.master then
      table.insert(buf, '(MASTER KEY)')
    end
    return table.concat(buf, ' ')
  end
}

ptypes.sRepContents = {
  format = '{ contents:{ 6*z64 } costs:{ 6*u4 } }';
  pprint = function(self, value, propdef, db)
    local buf = {}
    for i,v in ipairs(value.contents) do
      if #v > 0 then
        table.insert(buf, string.format('%s (¢%d)', v, value.costs[i]))
      end
    end
    return table.concat(buf, '; ')
  end
}

ptypes.sGunState = {
  format = '{ ammo:u4 condition:f4 silence:f4 mode:u4 mods:u4 }';
  pprint = function(self, value, propdef, db)
    return string.format(
      '%d rounds, %d%% durability, mod level %d',
      value.ammo, value.condition, value.mods)
  end
}

ptypes.cPhysDimsProp = {
  -- TODO: all the rest of the fields
  format = '{ x32 x:f4 y:f4 z:f4 x8 }';
  pprint = function(self, value)
    return '%dx%dx%d' % { value.x, value.y, value.z }
  end;
}

return ptypes
