local nm = require("galore.notmuch")
local u = require("galore.util")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local dia = require("galore.diagnostics")
local o = require("galore.opts")
local async = require("plenary.async")
local scheduler = require("plenary.async").util.scheduler

local Mb = Buffer:new()

local function get_message(message, i, total)
	local id = nm.message_get_id(message)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = nm.message_get_date(message)
	local matched = nm.message_get_flag(message, 0)
	local excluded = nm.message_get_flag(message, 1)
	return {
		id = id,
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
	}
end

local function cmp_newest(l1, l2)
	return l1.date > l2.date
end

local function cmp_oldest(l1, l2)
	return l1.date < l2.date
end

local function cmp_id(l1, l2)
	return l1.id > l2.id
end

function Mb:get_messages(db, search)
	self.State = {}
	local lines = {}
	local query = nm.create_query(db, search)
	for _, ex in ipairs(self.opts.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	local i = 1
	local first = true
	nm.query_set_sort(query, self.opts.sort)

	--- learn how async and the gc works, feels like we are 
	--- using gced memory, maybe we should do the callable table trick?
	local func = async.void(function ()
		for message in nm.query_get_messages(query) do
			local line = get_message(message, 1, 1)
			local formated = self.opts.show_message_description(line)
			table.insert(lines, formated)
			table.insert(self.State, line.id)
			if self.maxlines and self.maxlines < i then
				break
			end
			if i % 1000 == 0 then
				self:set_lines(-1, -1, false, lines)
				lines = {}
				if first then
					self:set_lines(0, 1, true, {})
					first = false
				end
				scheduler()
			end
			i = i + 1
		end
	self:set_lines(-1, -1, false, lines)
	if first then
		self:set_lines(0, 1, true, {})
	end
	self:lock()
	end)
	func()
	-- ppMessage(self, lines)
	-- dia.set_emph(self, lines, self.opts.emph)
	-- for thread in nm.query_get_threads(query) do
	-- 	local total = nm.thread_get_total_messages(thread)
	-- 	local tid = nm.thread_get_id(thread)
	-- 	local i = 1
	-- 	for message in nm.thread_get_messages(thread) do
	-- 		local line = get_message(message, tid, i, total)
	-- 		if line.matched then
	-- 			table.insert(state, line)
	-- 		end
	-- 		i = i + 1
	-- 	end
	-- end
	-- if self.opts.sort == "oldest" then
	-- 	table.sort(state, cmp_oldest)
	-- elseif self.opts.sort == "newest" then
	-- 	table.sort(state, cmp_newest)
	-- elseif self.opts.sort == "message-id" then
	-- 	table.sort(state, cmp_id)
	-- end
end

function Mb:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function (db)
		self:get_messages(db, self.search)
	end)
end

function Mb:tmb_search()
	local tmb = require("galore.thread_message_browser")
	local opts = o.bufcopy(self.opts)
	opts.parent = self
	tmb:create(self.search, opts)
end

function Mb:update(line_nr)
	local id = self.State[line_nr]
	local formated
	runtime.with_db(function(db)
		local message = nm.db_find_message(db, id)
		formated = self.opts.show_message_description(message)
	end)
	self:unlock()
	self:set_lines(line_nr-1, line_nr, true, {formated})
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
	o.mb_options(opts)
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
	}, Mb)
end

return Mb
