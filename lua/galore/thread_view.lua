-- When we view an thread, this is the view
local v = vim.api
local nm = require("galore.notmuch")
local Buffer = require("galore.lib.buffer")
local M = {}

--use vim.split(str, "\n")
local function split_lines(str)
	local lines = {}
	-- return vim.split(str, "[^\r\n]+", false)
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end

local function collect(iter)
	local box = {}
	for k, val in iter do
		box[k] = val
	end
	return box
end

local function filter(func, map)
	for k, v in pairs(map) do
		if not func(k, v) then
			map[k] = nil
		end
	end
end

local function format(iter)
	local box = {}
	for k, val in pairs(iter) do
		local str = string.gsub(val, "\n", "")
		table.insert(box, k .. ": " .. str)
	end
	return box
end
local function in_map(k, _)
	for _, a in ipairs(conf.values.headers) do
		if a == k then
			return true
		end
	end
	return false
end

function M.create(thread, kind)
	local tid = nm.thread_get_id(thread)

	if M.message_buffer then
		M.message_buffer:focus()
		return
	end
	-- try to find a buffer first
	Buffer.create({
		name = "galore-message",
		ft = "mail",
		kind = kind,
		cursor = "top",
		init = function(buffer)
			M.message_buffer = buffer

			for message in nm.thread_get_messages(thread) do
				-- v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
			end
			v.nvim_buf_set_lines(buffer.handle, 0, 1, true, {})
			-- local message = show_message(tid)
			-- local formated = format_message(message)

			-- set keybindings etc, later
			for bind, func in pairs(conf.values.key_bindings.thread_v) do
				v.nvim_buf_set_keymap(buffer.handle, "n", bind, func, { noremap = true, silent = true })
			end
		end,
	})
end

-- local function ppMail(message)
-- 	print(message.get_path())
-- end

-- function M.show_message(settings, thread)
-- local messages = thread:get_messages()
-- for _, message in ipairs(messages) do
-- 	local file = messages.get_path(message)
-- 	-- feed this into gmime?
-- 	for line in io.lines(file) do
-- 		print(line)
-- 	end
-- 	-- print(ppMail())
-- end
-- -- print(vim.inspect(thread:get_messages()))
-- end

function M.next() end

function M.prev() end

function M.open_attach() end

function M.save_attach() end

return M
