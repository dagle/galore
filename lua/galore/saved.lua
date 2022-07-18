-- saved is saved searches, the first view you get when you start notmuch
local nm = require("galore.notmuch")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local u = require("galore.util")
local runtime = require("galore.runtime")
local ordered = require("galore.lib.ordered")

local Saved = Buffer:new()
Saved.num = 0

local function make_entry(db, box, search, name, exclude)
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

local function gen_tags(searches)
	runtime.with_db(function (db)
		for tag in nm.db_get_all_tags(db) do
			local search = "tag:" .. tag
			ordered.insert(searches, search, {search, tag, true})
		end
	end)
end

local function gen_internal(searches)
	for search in runtime.iterate_saved() do
		ordered.insert(searches, search, {search, search, true})
	end
end

local function gen_excluded(searches)
	for _, tag in ipairs(config.values.exclude_tags) do
		local search = "tag:" .. tag
		ordered.insert(searches, search, {search, tag, false})
	end
end

local generators = {}

function Saved.get_searches()
	local searches = ordered.new()
	for _, gen in ipairs(generators) do
		gen(searches)
	end
	return searches
end

function Saved.Register(generator)
	table.insert(generators, generator)
end

local function ppsearch(tag)
	return string.format("%d(%d) %-30s (%s)", unpack(tag))
end

function Saved:refresh()
	self:unlock()
	self:clear()
	local box = {}
	local searches = self.get_searches()
	runtime.with_db(function (db)
		for _, value in ordered.pairs(searches) do
			make_entry(db, box, value[1], value[2], value[3])
		end
	end)
	local formated = vim.tbl_map(ppsearch, box)
	self:set_lines(0, 0, true, formated)
	self:set_lines(-2, -1, true, {})
	self.State = box
	vim.api.nvim_win_set_cursor(0, {1,0})
	self:lock()
end

function Saved:select()
	local line = vim.fn.line(".")
	return self.State[line]
end

function Saved:create(opts)
	self.num = self.num + 1
	return Buffer.create({
		name = u.gen_name("galore-saved", self.num),
		ft = "galore-saved",
		kind = opts.kind,
		cursor = "top",
		mappings = config.values.key_bindings.saved,
		init = function(buffer)
			buffer.Register(gen_tags)
			buffer.Register(gen_internal)
			buffer.Register(gen_excluded)
			buffer:refresh()
		end,
	}, Saved)
end

return Saved
