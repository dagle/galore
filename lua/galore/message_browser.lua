local nm = require("galore.notmuch")
local u = require("galore.util")
-- local nu = require("galore.notmuch-util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local dia = require("galore.diagnostics")

local Mb = Buffer:new()

local function get_message(message, tid, i, total)
	local id = nm.message_get_id(message)
	local filenames = u.collect(nm.message_get_filenames(message))
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = nm.message_get_date(message)
	local matched = nm.message_get_flag(message, 0)
	local excluded = nm.message_get_flag(message, 1)
	local keys = u.collect(nm.message_get_properties(message, "session-key", true))
	return {
		id = id,
		tid = tid,
		filenames = filenames,
		level = 0,
		-- pre = nil,
		index = i,
		total = total,
		date = date,
		from = from,
		sub = sub,
		tags = tags,
		matched = matched,
		excluded = excluded,
		keys = keys,
	}
end

local function cmp_time(l1, l2)
	return l2.date - l1.date
end

function Mb:get_messages(db, search)
	local state = {}
	local query = nm.create_query(db, search)
	for _, ex in ipairs(config.values.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	for thread in nm.query_get_threads(query) do
		local total = nm.thread_get_total_messages(thread)
		local tid = nm.thread_get_id(thread)
		local i = 1
		for message in nm.thread_get_messages(thread) do
			local line = get_message(message, tid, i, total)
			if line.matched then
				table.insert(state, line)
			end
			i = i + 1
		end
	end
	state = vim.fn.sort(state, cmp_time)
	self.State = state
end

function Mb:ppMessage(messages)
	local box = {}
	local lasttid
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(message, lasttid == message.tid)
		table.insert(box, formated)
		lasttid = message.tid
	end
	self:set_lines(-1, -1, true, box)
	self:set_lines(0, 1, true, {})
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

function Mb:tmb_search()
	local tmb = require("galore.thread_message_browser")
	local opts = vim.deepcopy(self.opts)
	tmb:create(self.search, opts)
end

--- move these
function Mb:update(start)
	local message = self.State[start]
	local formated = config.values.show_message_description(message)
	self:unlock()
	self:set_lines(start-1, start, true, {formated})
	self:lock()
end

function Mb:commands()
	vim.api.nvim_buf_create_user_command(self.handle, "GaloreChangetag", function (args)
		if args.args then
			local callback = require("galore.callback")
			callback.change_tag(self, args)
		end
	end, {
	nargs = "*",
	})
end

-- create a browser class
function Mb:create(search, opts)
	Buffer.create({
		name = "galore-messages: " .. search,
		ft = "galore-threads",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = config.values.key_bindings.message_browser,
		init = function(buffer)
			buffer.opts = opts
			buffer.search = search
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh()
			dia.set_emph(buffer, config.values.default_emph)
			buffer:commands()
			config.values.bufinit.message_browser(buffer)
		end,
	}, Mb)
end

return Mb
