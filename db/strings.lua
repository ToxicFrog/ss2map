-- .str file loader.
-- Use this as part of the db via db:load_strings('foo.str') and db:getString('file', 'key').

local strings = {}

local function loadFile(file)
  local str = {}
  local buf = '\n'..io.readfile(file):gsub('\r\n', '\n')..'\n'
  for k,v in buf:gmatch('\n([%w_]+):"(.-)"\n') do
    v = v:gsub('\\n', '\n') --:gsub('\\(.)', '%1')
    str[k] = v
  end
  return str
end

function strings.load(file)
  local r,e = pcall(loadFile, file)
  if not r then
    return nil,e
  else
    return e
  end
end

return strings
