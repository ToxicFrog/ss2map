-- Type-specific object name printing.

local objname = {}

local nametypes = {
  AudioLog = {
    'Object/Physical/Goodies/Audio Log',
    'Object/Traps/DataTraps/EmailTrap',
  };
  Chem = {
    'Object/Physical/Goodies/Chemicals',
  };
  Lock = {
    'Object/Physical/Functional/Controllers/Card slot',
  };
  Key = {
    'Object/Physical/Keys',
  };
}

function objname:getNameGeneric()
  local sym_name = self:getProperty('SymName')
  return self.name
    or sym_name and sym_name:pprint()
    or '[anonymous %s]' % self.meta.type
end

function objname:getNameForAudioLog()
  local prefix = objname.getNameGeneric(self)
  local titles = {};
  for i=1,9 do
    local prop = self:getProperty('Logs'..i)
    if prop then
      table.insert(titles, prop:pprint())
    end
  end
  if #titles > 0 then
    return prefix..': '..table.concat(titles, '; ')
  else
    return prefix
  end
end

function objname:getNameForChem()
  return objname.getNameGeneric(self)..': '..self:getShortDesc()
end

function objname:getNameForLock()
  local prefix = objname.getNameGeneric(self)
  local prop = self:getProperty('KeyDst')
  if prop then
    return prefix..': '..prop:pprint()
  else
    return prefix
  end
end

function objname:getNameForKey()
  local prefix = objname.getNameGeneric(self)
  local prop = self:getProperty('KeySrc')
  if prop then
    return prefix..': '..prop:pprint()
  else
    return prefix
  end
end

function objname:getName()
  -- Archetypes always get the generic name
  if self.meta.id < 0 then
    return objname.getNameGeneric(self)
  end

  local fqtn = self:getFQTN()
  if not fqtn then
    return objname.getNameGeneric(self)
  end

  for k,types in pairs(nametypes) do
    for _,type in pairs(types) do
      if fqtn:match('^'..type) then
        local name = objname['getNameFor'..k](self)
        if name then return name end
      end
    end
  end

  return objname.getNameGeneric(self)
end

return objname