-- A thread view after, after ou have done a search this is what is displayed
local v = vim.api
local nm = require("galore.notmuch")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")

local Tmb = Buffer:new()

local function get_message(message, tid, level, prestring, i, total)
	local id = nm.message_get_id(message)
	-- local filename = nm.message_get_filename(message)
	local filenames = u.collect(nm.message_get_filenames(message))
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = nm.message_get_date(message)
	-- Use enums for these?
	local matched = nm.message_get_flag(message, 0)
	local excluded = nm.message_get_flag(message, 1)
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
	}
end

-- NOP for now
local function sort(messages)
	return messages
end

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
		local sorted = u.collect(sort(nm.message_get_replies(message)))
		if #sorted > 0 then
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
		num = show_messages(sorted, level + 1, newstring, num + 1, total, tid, box, state)
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
		local formated = config.values.show_message_description(message)
		table.insert(box, formated)
	end
	return box
end

function Tmb:get_messages(db, search)
	local state = {}
	local threads = {}
	local start, stop = 1, 0
	local query = nm.create_query(db, search)
	for _, ex in ipairs(config.values.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
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



-- how should this work?
-- should we be able to match multiple tags
-- against multiple tags?
local function match_tag(tag, tags)
	for t in ipairs(tags) do
		if t == tag then
			return true
		end
	end
	return false
end

local function match(cond, line)
	for k, val in pairs(cond) do
		-- we match one tag, not all tags
		if k == "tags" then
			match_tag(cond[k], line[k])
		elseif line[k] ~= val then
			return false
		end
	end
	return true
end

function Tmb:threads_to_buffer()
	-- Tmb.threads_buffer:clear_sign_group("thread-expand")
	local i = 1
	for _, thread in ipairs(self.Threads) do
		if thread.expand then
			local lines = ppMessage(thread.messages)
			self:set_lines(-1, -1, true, lines)
			self:highlights(thread.messages, i, {matched=true})
			i = i + #thread.messages
			-- self:set_lines(-1, -1, true, item.messages)
			-- M.threads_buffer:place_sign(i, "uncollapsed", "thread-expand")
			-- i = i + #thread.messages
		else
			-- local lines = ppMessage(thread.messages)
			local line = config.values.show_message_description(thread.messages[1])
			self:set_lines(-1, -1, true, {line})
			self:highlights({thread.messages[1]}, i, {matched=true})
			i=i+1
			-- self:set_lines(-1, -1, true, { item.messages[1] })
			if #thread.messages ~= 1 then
				-- M.threads_buffer:place_sign(i, "collapsed", "thread-expand")
				-- i = i + 1
			end
		end
	end
	self:set_lines(0, 1, true, {})
end

function Tmb:highlights(messages, offset, cond)
	local i = offset
	for _, message in ipairs(messages) do
		if match(cond, message) then
			self:add_highlight(i, 0, -1, "nmEmph")
		end
		i = i + 1
	end
end

function Tmb:match_next(cond)
	local cur = vim.api.nvim_win_get_cursor(0)
	local virt_line = self.to_virtualline(self.Threads, cur[1])
	local next
	for i = virt_line, #self.State do
		if match(cond, self.State[i]) then
			next = i
			break
		end
	end
	local real_line = self.to_realline(self.Threads, next)
	vim.api.nvim_win_set_cursor(0, {real_line, cur[2]})
end

function Tmb:prev_matched(cond)
	local cur = vim.api.nvim_win_get_cursor(0)
	local virt_line = self.to_virtualline(self.Threads, cur[1])
	local next
	for i = 1, virt_line do
		local index = virt_line - i
		if match(cond, self.State[index]) then
			next = index
			break
		end
	end
	local real_line = self.to_realline(self.Threads, next)
	vim.api.nvim_win_set_cursor(0, {real_line, cur[2]})
end

function Tmb:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function(db)
		self:get_messages(db, self.search)
		self:threads_to_buffer()
	end)
	self:lock()
end

local function tail(list)
    return {unpack(list, 2)}
end

local function render_message(tmb, message, line)
	local formated = config.values.show_message_description(message)
	tmb:unlock()
	tmb:set_lines(line-1, line, true, {formated})
	tmb:lock()
end

function Tmb:update(start)
	local tm = self:get_thread_message(start)
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
			local messages = tail(thread.messages)
			self:set_lines(to, to, true, ppMessage(messages))
			self:highlights(messages, to, {matched=true})
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
	return line, line_info
end

--
function Tmb:prev(line)
	line = math.max(line - 1, 1)
	local line_info = self.State[line]
	return line, line_info
end

--- Maybe update the line when buffer is focused
--- Using autocmd
function Tmb:set_line(line)
	self.Line = line
end

function Tmb:select()
	local line = v.nvim_win_get_cursor(0)
	local virt_line = self.to_virtualline(self.Threads, line[1])
	self.Line = virt_line
	return virt_line, self.State[virt_line]
end

function Tmb:create(search, kind, parent)
	return Buffer.create({
		name = "galore-threads: " .. search,
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		parent = parent,
		mappings = config.values.key_bindings.thread_browser,
		init = function(buffer)
			buffer.search = search
			vim.api.nvim_win_set_option(0, "number", true)
			buffer:refresh(search)
			buffer.line = 1
			buffer:set_ns("galore_tmb")
		end,
	}, Tmb)
end

return Tmb
