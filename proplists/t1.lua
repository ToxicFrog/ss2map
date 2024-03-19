local ptypes = require 'proplists.common'

ptypes.sKeyInfo = {
  format = '{ master:b1 regions:m2 lock:u1 }';
  parseTail = function(self, name, type, tail)
    if name == 'RegionMask' then
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

return ptypes
