-- maybe move all of gm stuff to gm-util
-- this shouldn't be here
local gm = require("galore.gmime")
local ffi = require("ffi")
-- don't like this
local conf = require("galore.config")
local M = {}

-- u.print_table = function(tab)
--   print(vim.inspect(tab))
-- end

-- u.capture = function(cmd)
--   local f = assert(io.popen(cmd, 'r'))
--   local out = assert(f:read('*a')) -- *a means all content of pipe/file
--   f:close()
--   return out
-- end

-- u.split = function(s, delim)
--   local out = {}
--   for entry in string.gmatch(s, delim) do
--     table.insert(out, entry);
--   end
--   return out
-- end

function M.trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
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

-- get the ref if we are loading a draft
function M.get_ref(message)
	local ref_str = gm.object_get_header(ffi.cast("GMimeObject *", message), "References")
	local ref
	if ref_str then
		ref = gm.reference_parse(nil, ref_str)
	end
	local reply
	local reply_str = gm.g_mime_object_get_header(ffi.cast("GMimeObject *", message), "In-Reply-To")
	if reply_str then
		reply = gm.reference_parse(nil, ref_str)
	end
	return {
		reference = ref,
		in_reply_to = reply,
	}
end

-- make a new ref if we a making a reply
function M.make_ref(message)
  local ref_str = gm.object_get_header(ffi.cast("GMimeObject *", message), "References")
  local ref
  if ref_str then
    ref = gm.reference_parse(nil, ref_str)
  else
    ref = gm.new_ref()
  end
  local reply = nil
  local reply_str = gm.g_mime_object_get_header(ffi.cast("GMimeObject *", message), "Message-ID")
  if reply_str then
    reply = gm.reference_parse(nil, reply_str)
    gm.references_append(ref, reply_str)
  end
  return {
    reference = ref,
    in_reply_to = reply,
  }
  -- add old reply tail of refs
  -- add set
end

function M.viewable(part, control_bits)
	if gm.part_is_type(part, "text", "*") then
		return true
	end
	--
	-- if can_decrypt(part, control_bits) then
	-- 	return true
	-- end
	-- if it's encrypted return true if we can decrypt it
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

M.default_template = function ()
	return {
		"From: " .. conf.values.name .. " <" .. conf.values.primary_email .. ">",
		"To: ",
		"Subject: ",
	}
end


return M
