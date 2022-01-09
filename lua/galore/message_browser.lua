-- A message view after, after you have done a search this is what is displayed

local M = {}

local v = vim.api
local nm = require('galore.notmuch')
local u = require('galore.util')
local config = require('galore.config')
local Buffer = require('galore.lib.buffer')
M.State = {}

M.messages_buffer = nil

local function get_message(message, i)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = tonumber(nm.message_get_header(message, "Subject"))
	local ppdate = os.date("%Y-%m-%d", date)
	return {message, i, ppdate, from, sub, tags}
end

local function get_messages(db_path, search)
	local db = nm.db_open(db_path, 0)
	local box = {}
	local query = nm.create_query(db, search)
	local i = 0
	for message in nm.query_get_messages(query) do
		-- local mes = nm.message_get_messages(message)
		table.insert(box, get_message(message, i))
		i = i + 1
	end
	M.State = box
	nm.db_close(db)
	return box
end

local function ppMessage(message)
	local _, _, date, author, sub, tags = unpack(message)
	local t = table.concat(tags, " ")
	local formated = string.format("%s [1/1] %s; %s (%s)", date, author, sub, t)
	return string.gsub(formated, "\n", "")
end

-- update the content of the buffer
function M.ref()
	return M.threads_buffer
end

function M.create(search, kind)
	if M.message_browser_buffer then
		M.messages_buffer:focus()
		return
	end

	Buffer.create {
		name = "galore-messages",
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		init = function(buffer)
			M.message_browser_buffer = buffer

			local results = get_messages(config.values.db_path, search)
			local formated = vim.tbl_map(ppMessage, results)
			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)

			-- local results = get_threads(config.values.db_path, search)
			-- local formated = vim.tbl_map(ppThread, results)
			-- v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)
			v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})

			for bind, func in pairs(config.values.key_bindings.message_browser) do
				v.nvim_buf_set_keymap(buffer.handle, 'n', bind, func, { noremap=true, silent=true })
			end
		end
	}
end

function M:select()
	local line = vim.fn.line('.')
	return self.State[line]
end

return M
