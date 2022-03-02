-- A thread view after, after ou have done a search this is what is displayed
local v = vim.api
local nm = require("galore.notmuch")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")

local Tmb = Buffer:new()

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

local function line_info(message)
	return {
		nm.message_get_id(message),
		nm.message_get_filename(message),
		u.collect(nm.message_get_tags(message)),
	}
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
		table.insert(state, line_info(message))
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
	for _, val in ipairs(threads) do
		if val.start < i and not val.expand then
			i = i + #val.messages - 1
		else
			break
		end
	end
	return i
end
function Tmb.to_realline(threads, linenr)
	local i = linenr
	for _, val in ipairs(threads) do
		if val.start < i and not val.expand then
			i = i - #val.messages + 1
		else
			break
		end
	end
	return math.max(i, 1)
end

-- XXX shouldn't loop twice
function Tmb:toggle(linenr)
	local line = self.to_virtualline(self.Threads, linenr)
	for _, val in ipairs(self.Threads) do
		if val.start <= line and line <= val.stop then
			val.expand = not val.expand
			-- return val.expand, linenr + val.start - line
			return val.expand, linenr + val.start - line, val.stop, val
		end
	end
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

function Tmb:get_thread_message(vline)
	-- local vline = self.to_virtualline(self.Threads, line)

	local messages
	local start
	for _, val in ipairs(self.Threads) do
		if val.start <= vline and vline <= val.stop then
			start = val.start
			messages = val.messages
			break
		end
	end
	return messages[vline-start]
end

function Tmb:threads_to_buffer()
	-- Tmb.threads_buffer:clear_sign_group("thread-expand")
	for _, item in ipairs(self.Threads) do
		if item.expand then
			local lines = ppMessage(item.messages)
			self:set_lines(-1, -1, true, lines)
			-- self:set_lines(-1, -1, true, item.messages)
			-- M.threads_buffer:place_sign(i, "uncollapsed", "thread-expand")
			-- i = i + #item.messages
		else
			local lines = ppMessage(item.messages)
			self:set_lines(-1, -1, true, { lines[1]})
			-- self:set_lines(-1, -1, true, { item.messages[1] })
			if #item.messages ~= 1 then
				-- M.threads_buffer:place_sign(i, "collapsed", "thread-expand")
				-- i = i + 1
			end
		end
	end
	self:set_lines(0, 1, true, {})
end

function Tmb:refresh(search)
	self:unlock()
	self:clear()
	self:get_messages(config.values.db, search)
	self:threads_to_buffer()
	self:lock()
end

local function tail(list)
    return {unpack(list, 2)}
end

--- Being able to to do a partial update
--- Only works for a single line atm, easy fix
-- XXX
function Tmb:update(start, values)
	local value = values[1]
	self.State[start] = value
	-- P(self.Threads)
	local tm = self:get_thread_message(start)
	tm.tags = value[3]
	-- self.Threads[start].tags = value[3]
	-- self:set_lines
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
			-- self:set_lines(to, to, true, tail(thread.messages))
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

	local ret
	for _, val in ipairs(self.Threads) do
		if val.start <= vline and vline <= val.stop then
			ret = val.stop + 1
			break
		end
	end
	if ret ~= nil and ret < #self.State then
		self.Line = ret
		vim.api.nvim_win_set_cursor(0, {ret, col})
		return self.State[ret]
	end
end
-- hmmm.
-- function M:next_thread()
-- 	local line = vim.fn.getpos(".")[2]
-- 	local vline = self.to_virtualline(self.Threads, line[1])
--
-- 	local ret
-- 	for _, val in ipairs(self.Threads) do
-- 		if val.start <= vline and vline <= val.stop then
-- 			ret = val.stop + 1
-- 			break
-- 		end
-- 	end
-- 	if ret ~= nil and ret < #self.State then
-- 		self.Line = ret
-- 		return self.State[ret]
-- 	end
-- end

function Tmb:go_thread_prev()
	local pos = vim.api.nvim_win_get_cursor(0)
	local line = pos[1]
	local col = pos[2]
	local vline = self.to_virtualline(self.Threads, line)

	local ret
	for _, val in ipairs(self.Threads) do
		if val.start <= vline and vline <= val.stop then
			ret = val.start - 1
			break
		end
	end
	if ret ~= nil and ret > 0 then
		self.Line = ret
		vim.api.nvim_win_set_cursor(0, {ret, col})
		return self.State[ret]
	end
end

--
function Tmb:next()
	self.Line = math.min(self.Line + 1, #self.State)
	local nm_message = self.State[self.Line]
	return nm.message_get_filename(nm_message)
end

--
function Tmb:prev()
	self.Line = math.max(self.Line - 1, 1)
	local nm_message = self.State[self.Line]
	return nm.message_get_filename(nm_message)
end

function Tmb:select()
	local line = v.nvim_win_get_cursor(0)
	local virt_line = self.to_virtualline(self.Threads, line[1])
	self.Line = virt_line
	-- return self.State[virt_line], self.filenames[virt_line]
	return virt_line, self.State[virt_line]
end

function Tmb.create(search, kind, parent)
	Buffer.create({
		name = "galore-threads",
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		parent = parent,
		mappings = config.values.key_bindings.thread_browser,
		init = function(buffer)
			buffer:refresh(search)
		end,
	}, Tmb)
end

return Tmb
