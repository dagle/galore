local M = {}

function M.trim(s)
  return s:gsub('^%s*(.-)%s*$', '%1')
end

function M.id(arg)
  return arg
end

function M.make_keys(iter)
  local box = {}
  for v in iter do
    box[v] = true
  end
  return box
end

--- @param t table
--- @param sep string
--- @param i? number
--- @param j? number
function M.keys_concat(t, sep, i, j)
  return table.concat(vim.tbl_keys(t), sep, i, j)
end

function M.contains(list, item)
  for _, l in ipairs(list) do
    if l == item then
      return true
    end
  end
  return false
end

function M.string_setlength(str, len)
  local trimmed = vim.fn.strcharpart(str, 0, len)
  local tlen = vim.fn.strchars(trimmed)
  return trimmed .. string.rep(' ', len - tlen)
end

function M.reverse(list)
  local box = {}
  for i = #list, 1, -1 do
    box[#box + 1] = list[i]
  end
  return box
end

function M.upairs(list)
  local i = 1
  return function()
    if i < #list then
      local element = list[i]
      i = i + 1
      return element
    end
  end
end

-- Go over any iterator and just put all the values in an array
-- This can be slow but great for toying around
--- @param it function iterator to loop over
--- @param t? table
--- @param i? number index
--- @return array
function M.collect(it, t, i)
  local box = {}
  if t == nil then
    for v in it do
      table.insert(box, v)
    end
    return box
  else
    for _, v in it, t, i do
      table.insert(box, v)
    end
    return box
  end
end

function M.add_prefix(str, prefix)
  if not vim.startswith(str, prefix) then
    str = prefix .. ' ' .. str
  end
  return str
end

function M.basename(path)
  return string.gsub(path, '.*/(.*)', '%1')
end

function M.is_absolute(path)
  return path:sub(1, 1) == '/'
end

function M.save_path(path, default_path)
  path = vim.fn.expand(path)
  default_path = default_path or ''
  if not M.is_absolute(path) then
    path = default_path .. path
  end
  return path
end

function M.gen_name(name, num)
  if num == 1 then
    return name
  end
  return string.format('%s-%d', name, num)
end

function M.format(part, qoute)
  local box = {}
  for line in string.gmatch(part, '[^\n]+') do
    table.insert(box, line)
  end
  return box
end

function M.purge_empty(list)
  for i, v in ipairs(list) do
    if v == '' then
      table.remove(list, i)
    else
      break
    end
  end

  --- remove any empty line at the end of the list
  local stop = #list
  while stop > 0 do
    if list[stop] == '' then
      table.remove(list, stop)
      stop = stop - 1
    else
      break
    end
  end
end

function M.unmailto(addr)
  return addr:gsub('<mailto:(.*)>', '%1')
end

function M.get_kind(smods)
  local kind
  if smods.vertical then
    kind = "vertical"
  elseif smods.horizontal then
    kind = "horizontal"
  else
    kind = smods.split
  end
  return kind
end


return M
