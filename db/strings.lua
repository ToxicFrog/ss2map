-- .str file loader.
-- Use this as part of the db via db:load_strings('foo.str') and db:getString('file', 'key').

local strings = {}

function strings.load(file)
  local str = {}
  local buf = '\n'..assert(io.open(file, 'rb')):read('*a'):gsub('\r\n', '\n')..'\n'
  for k,v in buf:gmatch('\n([%w_]+):"(.-)"\n') do
    v = v:gsub('\\n', '\n') --:gsub('\\(.)', '%1')
    str[k] = v
  end
  return str
end

return strings
