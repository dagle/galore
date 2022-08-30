local nm = require("galore.notmuch")
local u = require("galore.util")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local dia = require("galore.diagnostics")
local o = require("galore.opts")
local async = require("plenary.async")
local scheduler = require("plenary.async").util.scheduler

local Tmb = Buffer:new()

-- this uses way to much memory
-- do we even need to store threads?
local function get_message(message, level, prestring, i, total)
	local id = nm.message_get_id(message)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = nm.message_get_date(message)
	local matched = nm.message_get_flag(message, 0)
	local excluded = nm.message_get_flag(message, 1)
	return {
		id = id,
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
	}
end

--- Draw the thread structure
local function show_messages(self, messages, level, prestring, num, total, start, cb)
	local j = 1
	for _, message in ipairs(messages) do
		local newstring
		if num == 0 then
			newstring = prestring
		elseif j == #messages then
			newstring = prestring .. "└─"
		else
			newstring = prestring .. "├─"
		end
		local children = u.collect(nm.message_get_replies(message))
		if self.opts.thread_reverse then
			vim.fn.reverse(children)
		end
		if #children > 0 then
			newstring = newstring .. "┬"
		else
			newstring = newstring .. "─"
		end
		cb(message, level, newstring, num, total, start)
		if num == 0 then
			newstring = prestring
		elseif #messages > j then
			newstring = prestring .. "│ "
		else
			newstring = prestring .. "  "
		end
		num = show_messages(self, children, level + 1, newstring, num + 1, total, start, cb)
		j = j + 1
	end
	return num
end

function Tmb:get_messages(db, search)
	local lines = {}
	local threads = {}
	self.State = {}
	local dias = {}

	local cb = function (message, level, newstring, num, total, start)
		local tm = get_message(message, level, newstring, num + 1, total)
		local formated = self.opts.show_message_description(tm)

		local h = dia.highlight(self.handle, tm, start+num-1, self.opts.emph)
		if h then
			table.insert(dias, h)
		end

		table.insert(lines, formated)
		table.insert(self.State, tm.id)
	end

	local query = nm.create_query(db, search)
	for _, ex in ipairs(self.opts.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	nm.query_set_sort(query, self.opts.sort)

	local func = async.void(function ()
		local start, stop = 1, 0
		local last_num = 0
		local first = true
		for thread in nm.query_get_threads(query) do
			local total = nm.thread_get_total_messages(thread)

			local messages = nm.thread_get_toplevel_messages(thread)
			local cmessages = u.collect(messages)
			show_messages(self, cmessages, 0, "", 0, total, start, cb)

			stop = stop + total

			-- don't do 1 line folds!
			if total ~= 1 then
				local threadinfo = {
					stop = stop,
					start = start,
				}
				table.insert(threads, threadinfo)
			end
			start = stop + 1

			if self.maxlines and self.maxlines < stop then
				break
			end
			if (start - last_num) > 1000 then
				last_num = start
				-- this is ugly
				if first then
					self:set_lines(-1, -1, false, lines)
					lines = {}
					self:set_lines(0, 1, true, {})
					first = false
				end
				scheduler()
			end
		end

		self:set_lines(-1, -1, false, lines)
		-- this is ugly
		if first then
			self:set_lines(0, 1, true, {})
		end

		local diaopts = { virtual_text = false, signs = false }
		vim.diagnostic.set(self.dians, self.handle, dias, diaopts)

		-- dia.set_emph(self, lines, self.opts.emph)

		--- add to state!
		-- self.State = state
		self:lock()
	end)
	func()
	-- we need to stop creating folds if we change window etc
	for _, thread in ipairs(threads) do
		self:create_fold(thread.start, thread.stop)
	end
end

function Tmb:mb_search()
	local mb = require("galore.message_browser")
	local opts = o.bufcopy(self.opts)
	opts.parent = self
	-- opts.parent = self.parent
	mb:create(self.search, opts)
end

--- Redraw the whole window
function Tmb:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function(db)
		self:get_messages(db, self.search)
	end)
end

function Tmb:update(db, line_nr)
	self:unlock()
	local id = self.State[line_nr]
	local cb = function (message, level, newstring, num, total, _)
		local tm = get_message(message, level, newstring, num + 1, total)
		if tm.id == id then
			local formated = self.opts.show_message_description(tm)
			self:set_lines(line_nr-1, line_nr, true, {formated})
		end
	end
	local query = nm.create_query(db, "mid:" .. id)
	for thread in nm.query_get_threads(query) do
		local total = nm.thread_get_total_messages(thread)
		local messages = nm.thread_get_toplevel_messages(thread)
		local cmessages = u.collect(messages)
		show_messages(self, cmessages, 0, "", 0, total, 0, cb)
		break
	end
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
	o.tmb_options(opts)
	return Buffer.create({
		name = opts.bufname(search),
		ft = "galore-browser",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = opts.key_bindings,
		init = function(buffer)
			buffer.search = search
			buffer.opts = opts
			buffer.diagnostics = {}
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh(search)
			buffer:commands()
			opts.init(buffer)
		end,
	}, Tmb)
end

return Tmb
