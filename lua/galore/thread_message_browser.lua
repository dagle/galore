-- A thread view after, after you have done a search this is what is displayed

local M = {}

local v = vim.api
local nm = require('galore.notmuch')
local u = require('galore.util')
local config = require('galore.config')
local Buffer = require('galore.lib.buffer')
M.State = {}
M.Cache = {}

M.threads_buffer = nil

local function get_message(message, level, prestring, i, tot)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = tonumber(nm.message_get_date(message))
	local ppdate = os.date("%Y-%m-%d ", date)
	-- local ppdate = os.date("%c", date)
	return {message, level, prestring, i, tot, ppdate, from, sub, tags}
end

local function reverse_cmp(m1, m2)
	return tonumber(nm.message_get_date(m1)) > tonumber(nm.message_get_date(m2))
end

local function sort(messages)
	if config.values.reverse_thread then
		local sorted = table.sort(u.collect(messages), reverse_cmp) or {}
		return ipairs(sorted)
	end
	return messages
end

local function show_messages(messages, level, prestring, num, tot, box)
	local show_message = function (lmessage, llevel, lprestring, lnum, ltot, lbox)
		table.insert(lbox, get_message(lmessage, llevel, lprestring, lnum, ltot))
		local sorted = sort(nm.message_get_replies(lmessage))
		local k = show_messages(sorted, llevel+1, lprestring, lnum, ltot, lbox)
		return k
	end
	local i = num
	local collected = u.collect(messages)
	local j = 1
	for _, message in ipairs(collected) do
		if j == #collected then
			prestring = prestring .. "└─"
		elseif j == 1 then
			prestring = prestring .. "├─"
		else
			prestring = prestring .. "│ "
		end
		i = show_message(message, level, prestring, i, tot, box)
		j = j + 1
	end
	return i
end

local function get_messages2(db, search)
	local box = {}
	local query = nm.create_query(db, search)
	for thread in nm.query_get_threads(query) do
		local i = 1
		local tot = nm.thread_get_total_messages(thread)
		local messages = nm.thread_get_toplevel_messages(thread)
		-- Maybe not
		show_messages(messages, 0, "", i, tot, box)
	end
	M.State = box
	return box
end


local function get_messages(db, search)
	local box = {}
	local query = nm.create_query(db, search)
	for thread in nm.query_get_threads(query) do
		local i = 1
		local mes = nm.thread_get_messages(thread)
		-- local mes = nm.thread_get_toplevel_messages(thread)
		-- notmuch_thread_get_toplevel_messages
		local tot = nm.thread_get_total_messages(thread)
		local current = #box + 1
		for message in mes do
			-- reverse the order of the messages in a thread, so the newest in
			-- the thread is at the the top
			if config.values.reverse_thread then
				box[current + (tot - i)] = get_message(message, 0, i, tot)
			else
				table.insert(box, get_message(message, 0, i, tot))
			end
			i = i + 1
		end
	end
	M.State = box
	return box
end

local function contains(list, item)
	for _, l in ipairs(list) do
		if l == item then
			return true
		end
	end
	return false
end

local function ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local _, level, prestring, num, tot, date, author, sub, tags = unpack(message)
		local t = table.concat(tags, " ")
		local formated = ""
		if num > 1 then
			-- if contains(tags, "unread") then
			-- if config.values.reverse_thread then
			-- 	formated = string.format("%s [%d/%d] %s; ◀╮ %s (%s)", date, num, tot, author, sub, t)
			-- else
				-- formated = string.format("%s [%d/%d] %s; ╰▶ %s (%s)", date, num, tot, author, sub, t)
				formated = string.format("%s [%d/%d] %s;  %s▶", date, num, tot, author, prestring)
			-- end
		else
			formated = string.format("%s [%d/%d] %s; %s (%s)", date, num, tot, author, sub, t)
		end
	    formated = string.gsub(formated, "\n", "")
		table.insert(box, formated)
	end
	return box
end

-- update the content of the buffer, thi
function M.refresh(search)
	local buffer = M.threads_buffer
	vim.api.nvim_buf_set_option(buffer.handle, "modifiable", true)
	buffer:clear()
	-- local results = get_messages(config.values.db_path, search)
	local results = get_messages2(config.values.db, search)
	-- local formated = vim.tbl_map(ppMessage, results)
	local formated = ppMessage(results)
	v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)

	v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
	vim.api.nvim_buf_set_option(buffer.handle, "modifiable", false)
end

function M.ref()
	return M.threads_buffer
end

function M.create(search, kind, ref)
	-- if M.threads_buffer and M.threads_buffer:is_open() then
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
		ref = ref,
		init = function(buffer)
			M.threads_buffer = buffer
			M.refresh(search)
			for bind, func in pairs(config.values.key_bindings.message_browser) do
				v.nvim_buf_set_keymap(buffer.handle, 'n', bind, func, { noremap=true, silent=true })
			end
		end
	}
end

-- function M:next_thread()
-- 	local line = v.nvim_win_get_cursor(0)
-- 	local message = self.State[line[1]]
-- 	local _, num, tot = unpack(message)
-- 	local nextl = line + tot - num + 1
-- 	nextl = math.min(nextl, #self.State)
-- 	v.nvim_win_set_cursor(0, {nextl, line[2]})
-- end
--
-- function M:next()
-- 	local line = v.nvim_win_get_cursor(0)
-- 	local nextl = math.min(line[1]+1, #self.State)
-- 	v.nvim_win_set_cursor(0, {nextl, line[2]})
-- end
--
-- function M:prev()
-- 	local line = v.nvim_win_get_cursor(0)
-- 	local prev = math.max(line[1]-1, 1)
-- 	v.nvim_win_set_cursor(0, {prev, line[2]})
-- end
--
-- function M:prev_thread()
-- 	local line = v.nvim_win_get_cursor(0)
-- 	local message = self.State[line[1]]
-- 	local _, num, tot = unpack(message)
-- 	local prev = line - num
-- 	prev = math.max(prev, 1)
-- 	v.nvim_win_set_cursor(0, {prev, line[2]})
-- end

function M.close()
	M.threads_buffer:close()
end

function M:select()
	-- local line = vim.fn.line('.')
	local line = v.nvim_win_get_cursor(0)
	return self.State[line[1]]
end

return M
