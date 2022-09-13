local Buffer = require("galore.lib.buffer")
local o = require("galore.opts")
local async = require("plenary.async")
local browser = require("galore.browser")

local Tmb = Buffer:new()

-- this uses way to much memory
-- do we even need to store threads?
-- local function get_message(message, level, prestring, i, total)
-- 	local id = nm.message_get_id(message)
-- 	local sub = nm.message_get_header(message, "Subject")
-- 	local tags = u.collect(nm.message_get_tags(message))
-- 	local from = nm.message_get_header(message, "From")
-- 	local date = nm.message_get_date(message)
-- 	local matched = nm.message_get_flag(message, 0)
-- 	local excluded = nm.message_get_flag(message, 1)
-- 	return {
-- 		id = id,
-- 		level = level,
-- 		pre = prestring,
-- 		index = i,
-- 		total = total,
-- 		date = date,
-- 		from = from,
-- 		sub = sub,
-- 		tags = tags,
-- 		matched = matched,
-- 		excluded = excluded,
-- 	}
-- end
--
-- --- Draw the thread structure
-- local function show_messages(self, messages, level, prestring, num, total, start, cb)
-- 	local j = 1
-- 	for _, message in ipairs(messages) do
-- 		local newstring
-- 		if num == 0 then
-- 			newstring = prestring
-- 		elseif j == #messages then
-- 			newstring = prestring .. "└─"
-- 		else
-- 			newstring = prestring .. "├─"
-- 		end
-- 		local children = u.collect(nm.message_get_replies(message))
-- 		if self.opts.thread_reverse then
-- 			vim.fn.reverse(children)
-- 		end
-- 		if #children > 0 then
-- 			newstring = newstring .. "┬"
-- 		else
-- 			newstring = newstring .. "─"
-- 		end
-- 		cb(message, level, newstring, num, total, start)
-- 		if num == 0 then
-- 			newstring = prestring
-- 		elseif #messages > j then
-- 			newstring = prestring .. "│ "
-- 		else
-- 			newstring = prestring .. "  "
-- 		end
-- 		num = show_messages(self, children, level + 1, newstring, num + 1, total, start, cb)
-- 		j = j + 1
-- 	end
-- 	return num
-- end
--
-- function Tmb:get_messages(db, search)
-- 	local lines = {}
-- 	local threads = {}
-- 	self.State = {}
-- 	local dias = {}
--
-- 	local cb = function (message, level, newstring, num, total, start)
-- 		local tm = get_message(message, level, newstring, num + 1, total)
-- 		local formated = self.opts.show_message_description(tm)
--
-- 		local h = dia.highlight(self.handle, tm, start+num-1, self.opts.emph)
-- 		if h then
-- 			table.insert(dias, h)
-- 		end
--
-- 		table.insert(lines, formated)
-- 		table.insert(self.State, tm.id)
-- 	end
--
-- 	local query = nm.create_query(db, search)
-- 	for _, ex in ipairs(self.opts.exclude_tags) do
-- 		nm.query_add_tag_exclude(query, ex)
-- 	end
-- 	nm.query_set_sort(query, self.opts.sort)
--
-- 	--- this shouldn't use async like this
-- 	--- we should use a live maker, that uses
-- 	--- nm-livesearcher to create entries
-- 	--- or scroll to creat entries. 
--
-- 	--- This is just bad and locks up the UI way to much
--
-- 	-- local func = async.void(function ()
-- 	local start, stop = 1, 0
-- 	local last_num = 0
-- 	local first = true
-- 	for thread in nm.query_get_threads(query) do
-- 		local total = nm.thread_get_total_messages(thread)
--
-- 		local messages = nm.thread_get_toplevel_messages(thread)
-- 		local cmessages = u.collect(messages)
-- 		show_messages(self, cmessages, 0, "", 0, total, start, cb)
--
-- 		stop = stop + total
--
-- 		if total ~= 1 then
-- 			local threadinfo = {
-- 				stop = stop,
-- 				start = start,
-- 			}
-- 			table.insert(threads, threadinfo)
-- 		end
-- 		start = stop + 1
--
-- 		if self.maxlines and self.maxlines < stop then
-- 			break
-- 		end
-- 		if (start - last_num) > 1000 then
-- 			last_num = start
-- 			-- this is ugly
-- 			if first then
-- 				self:set_lines(-1, -1, false, lines)
-- 				lines = {}
-- 				self:set_lines(0, 1, true, {})
-- 				first = false
-- 			end
-- 			-- scheduler()
-- 		end
-- 	end
--
-- 	self:set_lines(-1, -1, false, lines)
-- 	if first then
-- 		self:set_lines(0, 1, true, {})
-- 	end
--
-- 	local diaopts = { virtual_text = false, signs = false }
-- 	vim.diagnostic.set(self.dians, self.handle, dias, diaopts)
--
-- 	self:lock()
-- 	nm.db_close(db)
--
-- 	-- we need to stop creating folds if we change window etc
-- 	for _, thread in ipairs(threads) do
-- 		self:create_fold(thread.start, thread.stop)
-- 	end
-- end

-- can we add an indicator?
local function scroll(self)
	vim.api.nvim_create_autocmd({"CursorMoved, WinScrolled"}, {
		buffer = self.handle,
		callback = function ()
			local line = vim.api.nvim_win_get_cursor(0)[1]
			local nums = vim.api.nvim_buf_line_count(self.handle)
			local winsize = vim.api.nvim_win_get_height(0)
			local treshold = winsize*4
			if (nums - line) < treshold then
				-- We should make sure that we are alone!
				if self.runner then
					if not self.updating then
						self.updating = true
						local func = async.void(function ()
							self:unlock()
							self.runner.resume(math.max(treshold, self.opts.limit))
							self:lock()
							self.updating = false
						end)
						func()
					end
				end
			end
		end,
	})
end

local function tmb_get(self)
	local first = true
	return browser.get_entries(self, "show-tree", function (thread)
		local i = 0
		for _, message in ipairs(thread) do
			table.insert(self.State, message.id)
			-- if message.matched then
			-- 	local diagnostics = {
			-- 		bufnr = self.handle,
			-- 		lnum = num-1,
			-- 		end_lnum = num-1,
			-- 		col = 0,
			-- 		end_col = 100,
			-- 		severity = vim.diagnostic.severity.INFO,
			-- 		message = "matched!",
			-- 		source = "galore",
			-- 	}
			-- 	table.insert(self.dias, diagnostics)
			-- end
			if first then
				vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {message.entry})
				first = false
			else
				vim.api.nvim_buf_set_lines(self.handle, -1, -1, false, {message.entry})
			end
			i = i + 1
		end
		-- We need to api for folds etc and 
		-- we don't want dump all off them like this
		-- but otherwise this works
		-- if #thread > 1 then
		-- 	local threadinfo = {
		-- 		stop = i-1,
		-- 		start = linenr,
		-- 	}
		-- 	table.insert(self.threads, threadinfo)
		-- end
		return i
	end)
end

function Tmb:async_runner()
	self.updating = true
	self.dias = {}
	self.threads = {}
	local func = async.void(function ()
		self.runner = tmb_get(self)
		-- self.runner = get_messages(self)
		pcall(function ()
			self.runner.resume(self.opts.limit)
			self:lock()
			self.updating = false;
		end)
	end)
	func()
end

function Tmb:mb_search()
	local mb = require("galore.message_browser")
	local opts = o.bufcopy(self.opts)
	opts.parent = self
	mb:create(self.search, opts)
end

--- Redraw the whole window
function Tmb:refresh()
	if self.runner then
		self.runner.close()
		self.runner = nil
	end
	self:unlock()
	self:clear()
	self:async_runner()
end

-- have an autocmd for refresh?
function Tmb:trigger_refresh()
	-- trigger an refresh in autocmd
end

function Tmb:update(line_nr)
	local id = self.State[line_nr]
	browser.update_lines_helper("show-single-tree", self.opts.runtime.db_path, self.handle, "id:"..id, line_nr)
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

-- function Tmb:autocmd()

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
			if opts.limit then
				browser.scroll(buffer)
			end
			opts.init(buffer)
		end,
	}, Tmb)
end

return Tmb
