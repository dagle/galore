-- A thread view after, after ou have done a search this is what is displayed

local M = {}

local v = vim.api
local nm = require('galore.notmuch')
local u = require('galore.util')
local config = require('galore.config')
local Buffer = require('galore.lib.buffer')
local gu = require('galore.gmime-util')
M.State = {}
M.Cache = {}
M.Line = nil
M.Threads = {}

M.threads_buffer = nil

-- stop using M, use self!
local function get_message(message, level, prestring, i, tot)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = tonumber(nm.message_get_date(message))
	local ppdate = os.date("%Y-%m-%d ", date)
	return {level, prestring, i, tot, ppdate, from, sub, tags}
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
		table.insert(box, get_message(message, level, newstring, num+1, tot))
		table.insert(state, message)
		if num == 0 then
			newstring = prestring
		elseif #collected > j then
			newstring = prestring .. "│ "
		else
			newstring = prestring .. "  "
		end
		local sorted = sort(nm.message_get_replies(message))
		num = show_messages(sorted, level+1, newstring, num+1, tot, box, state)
		j = j + 1
	end
	return num
end

function M.to_virtualline(threads, linenr)
	local i = linenr
	for _, val in ipairs(threads) do
		if val.start < i and not val.expand then
			i = i + #val.messages - 1
		end
	end
	return i
end

-- XXX TODO
function M.to_realline(threads, linenr)
end

function M:toggle(linenr)
	local line = self.to_virtualline(self.Threads, linenr)
	for _, val in ipairs(self.Threads) do
		if val.start <= line and line <= val.stop then
			val.expand = not val.expand
			return val.expand, linenr + val.start - line
		end
	end
end

-- this should be move to config, it needs an easier interface
local function ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(unpack(message))
		table.insert(box, formated)
	end
	return box
end

local function get_messages(db, search)
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
		local threadinfo = {thread, stop=stop, start=start, messages=ppMessage(box), expand=true}
		table.insert(threads, threadinfo)
		start = stop + 1
	end
	M.Threads = threads
	M.State = state
	return threads
end

local function threads_to_buffer(threads)
	-- local i = 2
	M.threads_buffer:clear_sign_group("thread-expand")
	for _, item in ipairs(threads) do
		if item.expand then
			M.threads_buffer:set_lines(-1, -1, true, item.messages)
			-- M.threads_buffer:place_sign(i, "uncollapsed", "thread-expand")
			-- i = i + #item.messages
		else
			M.threads_buffer:set_lines(-1, -1, true, {item.messages[1]})
			-- M.threads_buffer:place_sign(i, "collapsed", "thread-expand")
			-- i = i + 1
		end
	end
	M.threads_buffer:set_lines(0, 1, true, {})
end

function M.refresh(search)
	local buffer = M.threads_buffer
	buffer:unlock()
	buffer:clear()
	local results = get_messages(config.values.db, search)
	threads_to_buffer(results)
	buffer:lock()
end

function M:redraw()
	local buffer = self.threads_buffer
	buffer:unlock()
	buffer:clear()
	threads_to_buffer(self.Threads)
	buffer:lock()
end

function M.ref()
	return M.threads_buffer
end

function M.create(search, kind, parent)
	if M.threads_buffer then
		M.refresh(search)
		M.threads_buffer:focus()
		return
	end

	Buffer.create {
		name = "galore-threads",
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		parent = parent,
		mappings = config.values.key_bindings.message_browser,
		init = function(buffer)
			M.threads_buffer = buffer
			M.refresh(search)
		end
	}
end

function M:next_thread()
	local line = vim.fn.getpos(".")[2]
	local vline = self.to_virtualline(self.Threads, line[1])

	local ret
	for _, val in ipairs(self.Threads) do
		if val.start <= vline and vline <= val.stop then
			ret = val.stop + 1
			break
		end
	end
	if ret ~= nil and ret < #self.State then
		self.Line = ret
		return self.State[ret]
	end
end

function M:prev_thread()
	local line = vim.fn.getpos(".")[2]
	local vline = self.to_virtualline(self.Threads, line[1])

	local ret
	for _, val in ipairs(self.Threads) do
		if val.start <= vline and vline <= val.stop then
			ret = val.start - 1
			break
		end
	end
	if ret ~= nil and ret > 0 then
		self.Line = ret
		return self.State[ret]
	end
end
--
function M:next()
	self.Line = math.min(self.Line+1, #self.State)
	return self.State[self.Line]
end
--
function M:prev()
	self.Line = math.max(self.Line-1, 1)
	return self.State[self.Line]
end

function M.close()
	M.threads_buffer:close()
end

function M:select()
	local line = v.nvim_win_get_cursor(0)
	local virt_line = self.to_virtualline(self.Threads, line[1])
	self.Line = virt_line
	return self.State[virt_line]
end

return M
