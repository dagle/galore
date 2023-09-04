local p = require "plenary.path"
local M = {}

function M.trim(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end

-- remove
function M.id(arg)
  return arg
end

-- remove use vim.tbl_keys
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

--- remove use vim.iter():find() instead
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
  return trimmed .. string.rep(" ", len - tlen)
end

-- remove use vim.iter():rev() instead
function M.reverse(list)
  local box = {}
  for i = #list, 1, -1 do
    box[#box + 1] = list[i]
  end
  return box
end

-- remove
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
--- @return any[]
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
    str = string.format("%s %s", prefix, str)
  end
  return str
end

--- @param path string
--- @param default_path string a default path to all paths that isn't absolute
--- @return string An expanded absolute path
function M.save_path(path, default_path)
  local path = p:new(path)
  path = p:new(path:expand())
  if not path:is_absolute() then
    local base = p:new(default_path)
    path = base:joinpath(path)
  end
  return path:expand()
end

function M.gen_name(name, num)
  if num == 1 then
    return name
  end
  return string.format("%s-%d", name, num)
end

--- vim.iter(part:gmatch("[^\n]+")):totable()
-- function M.format(part, qoute)
--   local box = {}
--   for line in string.gmatch(part, "[^\n]+") do
--     table.insert(box, line)
--   end
--   return box
-- end

function M.purge_empty(list)
  for i, v in ipairs(list) do
    if v == "" then
      table.remove(list, i)
    else
      break
    end
  end

  --- remove any empty line at the end of the list
  local stop = #list
  while stop > 0 do
    if list[stop] == "" then
      table.remove(list, stop)
      stop = stop - 1
    else
      break
    end
  end
end

function M.unmailto(addr)
  return addr:gsub("<mailto:(.*)>", "%1")
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
