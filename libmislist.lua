-- Implementation of mission listing interface.
-- Writes to *out*, so if you need it somewhere other than stdout, do the thing
-- with io.output() first and restore it after.
require 'util'

local function typeChain(db, obj, path, strip)
  if path then
    path = table.copy(path)
    table.insert(path, obj:getName())
  else
    path = { '' }
  end
  strip = strip or 0
  local has_parents = false

  for link in obj:getLinks('MetaProp') do
    if has_parents then
      -- inheritance tree splits here
      local prefix_size = #table.concat(path, ' -> ')
      typeChain(db, link:deref(), path, prefix_size)
    else
      typeChain(db, link:deref(), path, strip)
    end
    has_parents = true
  end
  if not has_parents then
    local buf = table.concat(path, ' -> ')
    if strip > 0 then
      printf('    ...%'..(strip-4)..'s%s\n', '...', buf:sub(strip+1))
    else
      printf('   %s\n', buf)
    end
  end
end

local function printObj(db, obj, pos, rot)
  printf('%s @ (%.2f,%.2f,%.2f) ϴ (H:%d° P:%d° B:%d°)\n',
    tostring(obj),
    pos.x, pos.y, pos.z,
    rot.z * 180, rot.y * 180, rot.x * 180)
end

local function listObjs(db, args)
  for id,brush in db:objects('brush') do
    -- Skip everything that isn't an object placement brush.
    if brush.type ~= -3 then goto continue end
    local obj = db:object(brush.primal)
    -- Thief maps sometimes have brushes pointing to nonexistent objects??
    if not obj then goto continue end
    printObj(db, obj, brush.position, brush.rotation)

    if args.ancestry then
      printf('  Ancestry:\n')
      typeChain(db, obj)
    end

    if args.links then
      printf('  Links:\n')
      for link in obj:getLinks() do
        printf('    %s\n', link)
      end
    end

    if args.props then
      -- TODO: this should sort props in the same way mishtml does
      local src = obj
      printf('  Dimensions: %dx%dx%d\n', brush.size.x*2, brush.size.y*2, brush.size.z*2)
      printf('  Properties:\n')
      for prop in obj:getProperties(args.inherited) do
        if prop.obj ~= src then
          src = prop.obj
          printf('  Properties via %s:\n', src)
        end
        printf('    %-16s: %s\n', prop.key_full, prop:pprint())
      end
    end

    if args.ancestry or args.links or args.props then
      printf('\n') -- insert blank line between blocks
    end

    ::continue::
  end
end

return {
  listObjects = listObjs;
}
