-- saved is saved searches, the first view you get when you start notmuch
local v = vim.api
-- change everything to galore
local nm = require("galore.notmuch")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")

local Saved = Buffer:new()
Saved.num = 0

local function get_tags(db)
	local box = {}
	for tag in nm.db_get_all_tags(db) do
		local search = "tag:" .. tag
		local q = nm.create_query(db, search)
		local i = nm.query_count_messages(q)
		table.insert(box, { i, tag, search })
	end
	return box
end

local function get_search_info(searches, db)
	local box = {}
	for _, search in pairs(searches) do
		local q = nm.create_query(db, search[2])
		local i = nm.query_count_messages(q)
		table.insert(box, { i, search[1], search[2] })
	end
	return box
end

local function ppsearch(tag)
	return string.format("%d %-20s (%s)", unpack(tag))
end

function Saved:select()
	local line = vim.fn.line(".")
	return self.state[line]
end

function Saved:get_searches()
	local search = get_search_info(config.values.saved_search, config.values.db)
	if config.values.show_tags then
		local tags = get_tags(config.values.db)
		search = vim.tbl_extend("keep", search, tags)
	end
	self.state = search
	return search
end

local function gen_name(num)
	if num == 1 then
		return "galore-saved"
	end
	return string.format("galore-saved-%d", num)
end


function Saved:create(kind)
	self.num = self.num + 1
	return Buffer.create({
		name = gen_name(self.num),
		ft = "galore-saved",
		kind = kind,
		cursor = "top",
		mappings = config.values.key_bindings.search,
		init = function(buffer)

			local search = buffer:get_searches()
			local formated = vim.tbl_map(ppsearch, search)
			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, formated)
			v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
		end,
	}, Saved)
end

return Saved
