local v = vim.api
local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local Mb = Buffer:new()
Mb.num = 0

local function get_message(message, i)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = tonumber(nm.message_get_header(message, "Subject"))
	local ppdate = os.date("%Y-%m-%d", date)
	return { message, i, ppdate, from, sub, tags }
end

local function get_messages(self, db, search)
	local box = {}
	local state = {}
	local query = nm.create_query(db, search)
	local i = 0
	for message in nm.query_get_messages(query) do
		table.insert(box, get_message(message, i))
		table.insert(state, nu.line_info(message))
		i = i + 1
	end
	self.State = state
	self.Message = box
	return box
end

local function ppMessage(buffer, messages)
	local box = {}
	for _, message in ipairs(messages) do
		local _, _, date, from, sub, tags = unpack(message)
		local formated = config.values.show_message_description(1, "", 1, 1, date, from, sub, tags)
		formated = string.gsub(formated, "\n", "")
		table.insert(box, formated)
	end
	v.nvim_buf_set_lines(buffer.handle, 0, 0, true, box)
	v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
end

function Mb:update(line, line_info)
	self.State[line] = line_info
	self.Message[line].tags = line_info[2]
end

function Mb:next(line)
	line = math.min(line + 1, #self.State)
	local line_info = self.State[line]
	return line_info[2], line
end

--
function Mb:prev(line)
	line = math.max(line - 1, 1)
	local line_info = self.State[line]
	return line_info[2], line
end

function Mb:select()
	local line = vim.fn.line(".")
	return line, self.State[line]
end

function Mb:create(search, kind)
	self.num = self.num + 1
	Buffer.create({
		name = u.gen_name("galore-messages", self.num),
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		mappings = config.values.key_bindings.message_browser,
		init = function(buffer)
			local results = get_messages(buffer, config.values.db, search)
			ppMessage(buffer, results)
		end,
	}, Mb)
end

return Mb
