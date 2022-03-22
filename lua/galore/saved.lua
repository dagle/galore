-- saved is saved searches, the first view you get when you start notmuch
local v = vim.api
-- change everything to galore
local nm = require("galore.notmuch")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local u = require("galore.util")
local runtime = require("galore.runtime")

local Saved = Buffer:new()
Saved.num = 0

local function saved_entry(db, search, name, box, exclude)
	local q = nm.create_query(db, search)
	if exclude then
		for _, ex in ipairs(config.values.exclude_tags) do
			nm.query_add_tag_exclude(q, ex)
		end
	end
	local unread_q = nm.create_query(db, search .. " and tag:unread")
	local i = nm.query_count_messages(q)
	local unread_i = nm.query_count_messages(unread_q)
	table.insert(box, { i, unread_i, name, search})
end

local function get_tags(db)
	local box = {}
	for tag in nm.db_get_all_tags(db) do
		local search = "tag:" .. tag
		saved_entry(db, search, tag, box, true)
	end
	return box
end

local function get_search_info(searches, db)
	local box = {}
	for _, search in ipairs(searches) do
		saved_entry(db, search[2], search[1], box, true)
	end
	return box
end

local function show_excluded(tags, db)
	local box = {}
	for _, tag in ipairs(tags) do
		local search = "tag:" .. tag
		saved_entry(db, search, tag, box, false)
	end
	return box
end

local function ppsearch(tag)
	return string.format("%d(%d) %-30s (%s)", unpack(tag))
end

function Saved:select()
	local line = vim.fn.line(".")
	return self.State[line]
end

function Saved:get_searches()
	local search = get_search_info(config.values.saved_search, runtime.db)
	if config.values.show_tags then
		local tags = get_tags(runtime.db)
		search = vim.tbl_extend("keep", search, tags)
	end
	if config.values.show_excluded then
		local exclude = show_excluded(config.values.exclude_tags, runtime.db)
		search = vim.tbl_extend("keep", search, exclude)
	end
	self.State = search
	return search
end


-- - [ ] A way to add searches not notmuch <-
function Saved:create(kind)
	self.num = self.num + 1
	return Buffer.create({
		name = u.gen_name("galore-saved", self.num),
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
