local conf = require("galore.config")
local M = {}

function M.trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function M.values(iter)
	local box = {}
	for v in iter do
		box[v] = true
	end
	return box
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
	return trimmed .. string.rep(" ", len-tlen)
end

function M.reverse(list)
	local box= {}
	for i=#list, 1, -1 do
		box[#box+1] = list[i]
	end
	return box
end

function M.upairs(list)
	local i = 1
	return function ()
		if i < #list then
			local element = list[i]
			i = i + 1
			return element
		end
	end
end

function M.collect(it)
  local box = {}
  for v in it do
    table.insert(box, v)
  end
  return box
end

function M.add_prefix(str, prefix)
	local start, _ = string.find(str, "^" .. prefix)
	if not start then
		str = prefix .. " " .. str
	end
	return str
end

function M.collect_keys(iter)
	local box = {}
	for k, _ in pairs(iter) do
		table.insert(box, k)
	end
	return box
end

function M.basename(path)
  	return string.gsub(path, ".*/(.*)", "%1")
end

function M.save_path(filename, default_path)
	local path
	default_path = default_path or ""
	if M.is_absolute(filename) then
		path = filename
	else
		path = default_path .. filename
	end
	return path
end

function M.split_lines(str)
	local lines = {}
	-- should convert everything to unix from dos.
	-- that we don't need to look for \r
	-- for s in str:gmatch("[^\n]+") do
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end

function M.format(part, qoute)
	local box = {}
	for line in string.gmatch(part, "[^\n]+") do
		table.insert(box, line)
		-- if qoute then
		-- 	table.insert(box, "> " .. line)
		-- end
	end
	return box
end

M.default_template = function ()
	return {
		"From: " .. conf.values.name .. " <" .. conf.values.primary_email .. ">",
		"To: ",
		"Subject: ",
	}
end

return M
