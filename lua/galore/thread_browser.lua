local nm = require("galore.notmuch")
local u = require("galore.util")
local o = require("galore.opts")
local runtime = require("galore.runtime")
local Buffer = require("galore.lib.buffer")

local Threads = Buffer:new()

local function get_thread(thread)
	local sub = nm.thread_get_subject(thread)
	local tags = u.collect(nm.thread_get_tags(thread))
	local authors = nm.thread_get_authors(thread)
	local tot = nm.thread_get_total_messages(thread)
	local matched = nm.thread_get_matched_messages(thread)
	local date = nm.thread_get_newest_date(thread)
	return {
		tags = tags,
		sub = sub,
		authors = authors,
		total = tot,
		matched = matched,
		date = date,
	}
end

local function show_thread(thread)
	local t = table.concat(thread.tags, " ")
	local date = os.date("%Y-%m-%d", thread.date)
	local len = vim.fn.strchars(thread.authors)
	-- TODO  25 shouldn't be hardcoded
	local authors = thread.authors .. string.rep(" ", 25 - len)
	local formated = string.format("%s [%02d/%02d] %s│ %s (%s)", date, thread.matched, thread.total, authors, thread.sub, t)
	formated = string.gsub(formated, "[\r\n]", "")
	return formated
end

function Threads:get_threads(db, search)
	self.State = {}
	local box = {}

	local query = nm.create_query(db, search)
	for _, ex in ipairs(self.opts.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	nm.query_set_sort(query, self.opts.sort)
	for thread in nm.query_get_threads(query) do
		local tid = nm.thread_get_id(thread)
		local tm = get_thread(thread)
		local formated = show_thread(tm)
		table.insert(self.State, tid)
		table.insert(box, formated)
	end
	self:set_lines(-1, -1, true, box)
	self:set_lines(0, 1, true, {})
end

function Threads:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function (db)
		self:get_threads(db, self.search)
	end)
	self:lock()
end

function Threads:commands()
end

function Threads:select_thread()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	return line, self.State[line]
end

function Threads:create(search, opts)
	o.threads_options(opts)
	Buffer.create({
		name = opts.bufname(search),
		ft = "galore-browser",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = opts.key_bindings,
		init = function(buffer)
			buffer.opts = opts
			buffer.search = search
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh()
			buffer:commands()
			opts.init(buffer)
		end,
	}, Threads)
end

return Threads
