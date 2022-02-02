local M = {}

local v = vim.api
local nm = require("galore.notmuch")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
M.State = {}

M.messages_buffer = nil

local function get_message(message, i)
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = tonumber(nm.message_get_header(message, "Subject"))
	local ppdate = os.date("%Y-%m-%d", date)
	return { message, i, ppdate, from, sub, tags }
end

local function get_messages(db, search)
	local box = {}
	local query = nm.create_query(db, search)
	local i = 0
	for message in nm.query_get_messages(query) do
		table.insert(box, get_message(message, i))
		i = i + 1
	end
	M.State = box
	return box
end

local function ppMessage(buffer, messages)
	local box = {}
	for _, message in ipairs(messages) do
		local _, _, date, author, sub, tags = unpack(message)
		local t = table.concat(tags, " ")
		local formated = string.format("%s [1/1] %s; %s (%s)", date, author, sub, t)
		formated = string.gsub(formated, "\n", "")
		table.insert(box, formated)
	end
	v.nvim_buf_set_lines(buffer.handle, 0, 0, true, box)
	v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})

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

	Buffer.create({
		name = "galore-messages",
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		mappings = config.values.key_bindings.message_browser,
		init = function(buffer)
			M.message_browser_buffer = buffer

			local results = get_messages(config.values.db, search)
			ppMessage(buffer, results)
			-- local results = get_threads(config.values.db_path, search)
			-- local formated = vim.tbl_map(ppThread, results)
			-- v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)
		end,
	})
end

function M:select()
	local line = vim.fn.line(".")
	return self.State[line]
end

return M
