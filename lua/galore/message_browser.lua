local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local Mb = Buffer:new()

function Mb:get_messages(db, search)
	local state = {}
	local query = nm.create_query(db, search)
	for _, ex in ipairs(config.values.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	for message in nm.query_get_messages(query) do
		table.insert(state, nu.get_message(message))
	end
	self.State = state
end

function Mb:ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(message)
		table.insert(box, formated)
	end
	self:set_lines(0, 0, true, box)
	self:set_lines(-2, -1, true, {})
end

function Mb:update(start)
	local message = self.State[start]
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

function Mb:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function (db)
		self:get_messages(db, self.search)
	end)
	self:ppMessage(self.State)
	self:lock()
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
			buffer:refresh()
		end,
	}, Mb)
end

return Mb
