local ptypes = require 'proplists.common'

-- TODO: in Thief 1, the enum field is named RegionMask and is only 2 bytes long, not 4.
ptypes.sKeyInfo = {
  format = '{ master:b1 regions:m4 lock:u1 }';
  parseTail = function(self, name, type, tail)
    if name == 'RegionID' then
      ptypes.bitflags.parseTail(self, name, type, tail)
    end
  end;
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

ptypes.cPhysDimsProp = {
  -- TODO: all the rest of the fields
  format = '{ x32 x:f4 y:f4 z:f4 x8 }';
  pprint = function(self, value)
    return '%dx%dx%d' % { value.x, value.y, value.z }
  end;
}

return ptypes
