-- A thread view after, after you have done a search this is what is displayed

local M = {}

local v = vim.api
local nm = require("galore.notmuch")
local u = require("galore.util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
M.State = {}

M.threads_buffer = nil

local function get_threads(db_path, search)
	local db = nm.db_open(db_path, 0)
	local box = {}
	local query = nm.create_query(db, search)
	for thread in nm.query_get_threads(query) do
		local sub = nm.thread_get_subject(thread)
		local tags = nm.thread_get_tags(thread)
		local authors = nm.thread_get_authors(thread)
		local tot = nm.thread_get_total_messages(thread)
		local matched = nm.thread_get_matched_messages(thread)
		local date = nm.thread_get_newest_date(thread)
		local ppdate = os.date("%Y-%m-%d", date)
		-- local mes = nm.thread_get_toplevel_messages(thread)
		table.insert(box, { thread, ppdate, tot, matched, authors, sub, tags })
	end
	M.State = box
	return box
end

local function ppThread(thread)
	local _, date, tot, match, author, sub, tags = unpack(thread)
	local s = table.concat(u.collect(tags), " ")
	local formated = string.format("%s [%d/%d] %s; %s (%s)", date, tot, match, author, sub, s)
	-- do real stripping etc
	return string.gsub(formated, "\n", "")
end

-- update the content of the buffer
function M.refresh() end

function M.create(search, kind)
	if M.threads_buffer then
		M.threads_buffer:focus()
		return
	end

	Buffer.create({
		name = "galore-threads",
		ft = "galore-threads",
		kind = kind,
		cursor = "top",
		init = function(buffer)
			M.threads_buffer = buffer

			local results = get_threads(config.values.db_path, search)
			local formated = vim.tbl_map(ppThread, results)
			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)

			v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})

			for bind, func in pairs(config.values.key_bindings.thread_browser) do
				v.nvim_buf_set_keymap(buffer.handle, "n", bind, func, { noremap = true, silent = true })
			end
		end,
	})
end

function M:select()
	local line = vim.fn.line(".")
	return self.State[line]
end

return M
