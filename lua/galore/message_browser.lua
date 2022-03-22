local v = vim.api
local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local Mb = Buffer:new()

local function get_message(message)
	local id = nm.message_get_id(message)
	local filename = nm.message_get_filename(message)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = tonumber(nm.message_get_header(message, "Subject"))
	return {
		id = id,
		filename = filename,
		level = 1,
		pre = "",
		index = 1,
		total = 1,
		date = date,
		from = from,
		sub = sub,
		tags = tags
	}
end

function Mb:get_messages(db, search)
	local state = {}
	local query = nm.create_query(db, search)
	for _, ex in ipairs(config.values.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	for message in nm.query_get_messages(query) do
		table.insert(state, get_message(message))
	end
	self.State = state
end

function Mb:ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(message)
		formated = string.gsub(formated, "\n", "")
		table.insert(box, formated)
	end
	self:set_lines(0, 0, true, box)
	self:set_lines(-2, -1, true, {})
end

function Mb:update(start)
	local message = self.State
	local formated = config.values.show_message_description(message)
	self:unlock()
	self:set_lines(start-1, start, true, {formated})
	self:lock()
end

function Mb:next(line)
	line = math.min(line + 1, #self.State)
	local line_info = self.State[line]
	return line_info, line
end

--
function Mb:prev(line)
	line = math.max(line - 1, 1)
	local line_info = self.State[line]
	return line_info, line
end

function Mb:select()
	local line = vim.fn.line(".")
	return line, self.State[line]
end

function Mb:set_line(line)
	self.Line = line
end

function Mb:create(search, kind, parent)
	Buffer.create({
		name = "galore-messages: " .. search,
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		parent = parent,
		mappings = config.values.key_bindings.message_browser,
		init = function(buffer)
			buffer.search = search
			buffer:get_messages(runtime.db, search)
			buffer:ppMessage(buffer.State)
		end,
	}, Mb)
end

return Mb
