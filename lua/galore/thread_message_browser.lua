-- A thread view after, after ou have done a search this is what is displayed
local nm = require("galore.notmuch")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local dia = require("galore.diagnostics")
-- local callback = require("galore.callback")

local Tmb = Buffer:new()

local function get_message(message, tid, level, prestring, i, total)
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
		level = level,
		pre = prestring,
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

--- Draw the thread structure
local function show_messages(messages, level, prestring, num, total, tid, box, state)
	for j, message in ipairs(messages) do
		local newstring
		if num == 0 then
			newstring = prestring
		elseif j == #messages then
			newstring = prestring .. "└─"
		else
			newstring = prestring .. "├─"
		end
		local children = u.collect(nm.message_get_replies(message))
		if config.values.thread_reverse then
			vim.fn.reverse(children)
		end
		if #children > 0 then
			newstring = newstring .. "┬"
		else
			newstring = newstring .. "─"
		end
		local tm = get_message(message, tid, level, newstring, num + 1, total)
		table.insert(box, tm)
		table.insert(state, tm)
		if num == 0 then
			newstring = prestring
		elseif #messages > j then
			newstring = prestring .. "│ "
		else
			newstring = prestring .. "  "
		end
		num = show_messages(children, level + 1, newstring, num + 1, total, tid, box, state)
	end
	return num
end

function Tmb:get_messages(db, search)
	local state = {}
	local threads = {}
	local start, stop = 1, 0
	local query = nm.create_query(db, search)
	for _, ex in ipairs(config.values.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	nm.query_set_sort(query, config.values.sort)
	for thread in nm.query_get_threads(query) do
		local box = {}
		local total = nm.thread_get_total_messages(thread)
		local messages = nm.thread_get_toplevel_messages(thread)
		local cmessages = u.collect(messages)
		local tid = nm.thread_get_id(thread)
		show_messages(cmessages, 0, "", 0, total, tid, box, state)
		stop = stop + total
		local threadinfo = {
			thread = tid,
			stop = stop,
			start = start,
			messages = box,
			expand = config.values.thread_expand,
		}
		table.insert(threads, threadinfo)
		start = stop + 1
	end
	self.Threads = threads
	self.State = state
	return threads
end

local function ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(message)
		table.insert(box, formated)
	end
	return box
end

function Tmb:threads_to_buffer()
	for _, thread in ipairs(self.Threads) do
		local lines = ppMessage(thread.messages)
		self:set_lines(-1, -1, true, lines)
	end
	self:set_lines(0, 1, true, {})
	local i = 1
	for _, thread in ipairs(self.Threads) do
		local next = i + #thread.messages
		-- maybe not this?
		-- if #thread.messages > 1 then
			self:create_fold(i, next-1)
		-- end
		i = next
	end
end

--- Redraw the whole window
function Tmb:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function(db)
		self:get_messages(db, self.search)
		self:threads_to_buffer()
	end)
	self:lock()
end

function Tmb:update(start)
	local formated = config.values.show_message_description(self.State[start])
	self:unlock()
	self:set_lines(start-1, start, true, {formated})
	self:lock()
end

function Tmb:commands()
	vim.api.nvim_buf_create_user_command(self.handle, "GaloreChangetag", function (args)
		if args.args then
			local callback = require("galore.callback")
			callback.change_tag(self, args)
		end
	end, {
	nargs = "*",
	})
end


--- Create a browser grouped by threads
--- @param search string a notmuch search string
--- @param opts table
--- @return any
function Tmb:create(search, opts)
	return Buffer.create({
		name = "galore-threads: " .. search,
		ft = "galore-threads",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = config.values.key_bindings.thread_browser,
		init = function(buffer)
			buffer.search = search
			buffer.line = 1
			buffer.diagnostics = {}
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh(search)
			dia.set_emph(buffer, config.values.default_emph)
			buffer:commands()
			config.values.bufinit.thread_browser(buffer)
		end,
	}, Tmb)
end

return Tmb
