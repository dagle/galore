-- A thread view after, after ou have done a search this is what is displayed
local v = vim.api
local nm = require("galore.notmuch")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local nu = require("galore.notmuch-util")

local Tmb = Buffer:new()
Tmb.num = 0

local function get_message(message, level, prestring, i, tot)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = nm.message_get_date(message)
	local ppdate = os.date("%Y-%m-%d ", date)
	return { level, prestring, i, tot, ppdate, from, sub, tags }
end

local function sort(messages)
	return messages
end

local function show_messages(messages, level, prestring, num, tot, box, state)
	local collected = u.collect(messages)
	local j = 1
	for _, message in ipairs(collected) do
		local newstring
		if num == 0 then
			newstring = prestring
		elseif j == #collected then
			newstring = prestring .. "└─"
		else
			newstring = prestring .. "├─"
		end
		table.insert(box, get_message(message, level, newstring, num + 1, tot))
		-- table.insert(state, message)
		table.insert(state, nu.line_info(message))
		if num == 0 then
			newstring = prestring
		elseif #collected > j then
			newstring = prestring .. "│ "
		else
			newstring = prestring .. "  "
		end
		local sorted = sort(nm.message_get_replies(message))
		num = show_messages(sorted, level + 1, newstring, num + 1, tot, box, state)
		j = j + 1
	end
	return num
end

function Tmb.to_virtualline(threads, linenr)
	local i = linenr
	for _, thread in ipairs(threads) do
		if thread.start < i and not thread.expand then
			i = i + #thread.messages - 1
		elseif thread.start > i then
			break
		end
	end
	return i
end

function Tmb.to_realline(threads, linenr)
	local i = linenr
	for _, thread in ipairs(threads) do
		if thread.start < linenr and not thread.expand then
			i = i - #thread.messages + 1
		end
	end
	return math.max(i, 1)
end

local function binsearch(threads, between, low, max)
	local mid = low + math.floor(max / 2)
	local t = threads[mid]
	if t.start <= between and between <= t.stop then
		return t
	elseif between > t.stop then
		return binsearch(threads, between, low, mid)
	elseif t.start > between then
		return binsearch(threads, between, mid, max)
	end
end

function Tmb:get_thread(vline)
	for _, thread in ipairs(self.Threads) do
		if thread.start <= vline and vline <= thread.stop then
			return thread
		end
	end
end

function Tmb:get_thread_message(vline)
	local thread = self:get_thread(vline)
	return thread.messages[vline-thread.start+1]
end

-- XXX shouldn't loop twice
function Tmb:toggle(linenr)
	local line = self.to_virtualline(self.Threads, linenr)
	local thread = self:get_thread(line)
	thread.expand = not thread.expand
	local start = linenr + thread.start - line
	local stop = start + #thread.messages - 1
	return thread.expand, start, stop, thread
end

local function ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(unpack(message))
		table.insert(box, formated)
	end
	return box
end

function Tmb:get_messages(db, search)
	local state = {}
	local threads = {}
	local start, stop = 1, 0
	local query = nm.create_query(db, search)
	for thread in nm.query_get_threads(query) do
		local box = {}
		local tot = nm.thread_get_total_messages(thread)
		local messages = nm.thread_get_toplevel_messages(thread)
		show_messages(messages, 0, "", 0, tot, box, state)
		stop = stop + tot
		local threadinfo = { thread, stop = stop, start = start, messages = box, expand = true }
		-- local threadinfo = { thread, stop = stop, start = start, messages = ppMessage(box), expand = true }
		table.insert(threads, threadinfo)
		start = stop + 1
	end
	self.Threads = threads
	self.State = state
	return threads
end


function Tmb:threads_to_buffer()
	-- Tmb.threads_buffer:clear_sign_group("thread-expand")
	self:unlock()
	self:clear()
	for _, thread in ipairs(self.Threads) do
		if thread.expand then
			local lines = ppMessage(thread.messages)
			self:set_lines(-1, -1, true, lines)
			-- self:set_lines(-1, -1, true, item.messages)
			-- M.threads_buffer:place_sign(i, "uncollapsed", "thread-expand")
			-- i = i + #item.messages
		else
			local lines = ppMessage(thread.messages)
			self:set_lines(-1, -1, true, { lines[1]})
			-- self:set_lines(-1, -1, true, { item.messages[1] })
			if #thread.messages ~= 1 then
				-- M.threads_buffer:place_sign(i, "collapsed", "thread-expand")
				-- i = i + 1
			end
		end
	end
	self:set_lines(0, 1, true, {})
	self:lock()
end

function Tmb:refresh(search)
	self:get_messages(config.values.db, search)
	self:threads_to_buffer()
end

local function tail(list)
    return {unpack(list, 2)}
end

--- XXX
local function render_message(tmb, message, line)
	local formated = config.values.show_message_description(unpack(message))
	tmb:unlock()
	tmb:set_lines(line-1, line, true, {formated})
	tmb:lock()
end

--- adds an message and updates the thread? Or something?
--- Maybe not?
-- local function add_message()
-- end
--- Being able to to do a partial update
--- Only works for a single line atm, easy fix
-- XXX
function Tmb:update(start, values)
	local value = values[1]
	self.State[start] = value
	local tm = self:get_thread_message(start)
	tm[8] = value[3]
	render_message(self, tm, start)
end

-- ugly but works for now
-- not general enough
function Tmb:redraw(expand, to, stop, thread)
	self:unlock()
	if not to then
		self:clear()
		self:threads_to_buffer()
	else
		if expand then
			self:set_lines(to, to, true, tail(ppMessage(thread.messages)))
		else
			self:set_lines(to, stop, true, {})
		end
	end
	self:lock()
end

function Tmb:go_thread_next()
	local pos = vim.api.nvim_win_get_cursor(0)
	local line = pos[1]
	local col = pos[2]
	local vline = self.to_virtualline(self.Threads, line)

	local tm = self:get_thread(vline)
	if tm then
		local lline = math.min(tm.stop + 1, #self.State)
		local real = self.to_realline(self.Threads, lline)
		vim.api.nvim_win_set_cursor(0, {real, col})
	end
end

function Tmb:go_thread_prev()
	local pos = vim.api.nvim_win_get_cursor(0)
	local line = pos[1]
	local col = pos[2]
	local vline = self.to_virtualline(self.Threads, line)

	local tm = self:get_thread(vline - 1)
	if tm then
		local lline
		if tm.start == vline then
			lline = math.max(tm.start - 1, 1)
		else
			lline = tm.start
		end
		local real = self.to_realline(self.Threads, lline)
		vim.api.nvim_win_set_cursor(0, {real, col})
	end
end

--
function Tmb:next(line)
	line = math.min(line + 1, #self.State)
	local line_info = self.State[line]
	return line_info[2], line
end

--
function Tmb:prev(line)
	line = math.max(line - 1, 1)
	local line_info = self.State[line]
	return line_info[2], line
end

--- Maybe update the line when buffer is focused
--- Using autocmd
function Tmb:set_line(line)
	--- should do to_realline and maybe we shouldn't have a self.Line
	self.Line = line
end

function Tmb:select()
	local line = v.nvim_win_get_cursor(0)
	local virt_line = self.to_virtualline(self.Threads, line[1])
	self.Line = virt_line
	return virt_line, self.State[virt_line]
end

function Tmb:create(search, kind, parent)
	self.num = self.num + 1
	return Buffer.create({
		name = u.gen_name("galore-threads", self.num),
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		parent = parent,
		mappings = config.values.key_bindings.thread_browser,
		init = function(buffer)
			vim.api.nvim_win_set_option(0, "number", true)
			buffer:refresh(search)
			buffer.line = 1
		end,
	}, Tmb)
end

return Tmb
