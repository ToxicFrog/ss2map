-- Hand-crafted deserializers for property types that we can't automatically decode
-- just from the contents of proplist.txt

local vstruct = require 'vstruct'
local ptypes = {}

ptypes.Position = {
  format = 'pos:{ x:f4 y:f4 z:f4 } x4 rot:{ x:pu2,15 y:pu2,15 z:pu2,15 }';
  pprint = function(self)
    local val = self.value
    return '(%.2f,%.2f,%.2f) ϴ (H:%d° P:%d° B:%d°)' %{
      val.pos.x, val.pos.y, val.pos.z, val.rot.z*180, val.rot.y*180, val.rot.x*180
    }
  end;
}

for k,v in pairs(ptypes) do
  v.format = vstruct.compile(v.format)
  -- autopromote string-only pprints to wrappers around string.interpolate?
end

return ptypes
