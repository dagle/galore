-- saved is saved searches, the first view you get when you start notmuch
local v = vim.api
-- change everything to galore
local nm = require('galore.notmuch')
local Buffer = require('galore.lib.buffer')
local config = require('galore.config')

local M = {}

-- Maybe make an easy way to add tags

-- is this a good idea?
-- figure out how to do state in a good way
-- Should I have a presitant db connection?
M.State = {}

M.savef_buffer = nil

local function get_tags(db)
  -- local db = nm.db_open(db_path, 0)
  local box = {}
  for tag in nm.db_get_all_tags(db) do
    local search = "tag:".. tag
    local q = nm.create_query(db,search)
	local i = nm.query_count_messages(q)
    table.insert(box, {i, tag, search})
  end
  -- nm.db_close(db)
  return box
end

local function get_search_info(searches, db)
	local box = {}
	for _, search in pairs(searches) do
		local q = nm.create_query(db, search[2])
		local i = nm.query_count_messages(q)
		table.insert(box, {i, search[1], search[2]})
	end
	return box
end

local function ppsearch(tag)
  return string.format("%d %-20s (%s)", unpack(tag))
end

function M.ref()
	return M.saved_buffer
end

local function get_searches()
	local search = get_search_info(config.values.saved_search, config.values.db)
	if config.values.show_tags then
		local tags = get_tags(config.values.db)
		search = vim.tbl_extend("keep", search, tags)
	end
	M.State = search
	return search
end

function M.create(kind)
	if M.saved_buffer and M.saved_buffer:is_open() then
		M.saved_buffer:focus()
		return
	end
	-- try to find a buffer first
	Buffer.create {
		name = "galore-saved",
		ft = "galore-saved",
		kind = kind,
		cursor = "top",
		init = function(buffer)
			M.saved_buffer = buffer

			local search = get_searches()
			local formated = vim.tbl_map(ppsearch, search)
			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)
			-- delete last line
			v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})

			-- set keybindings etc, later
			for bind, func in pairs(config.values.key_bindings.search) do
				v.nvim_buf_set_keymap(buffer.handle, 'n', bind, func, { noremap=true, silent=true })
			end
		end,
	}
end

function M.close()
	M.saved_buffer:close()
end

-- this should actually select stuff
function M:select()
	local line = vim.fn.line('.')
	return self.State[line]
end

return M
