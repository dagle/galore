local nm = require("galore.notmuch")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local ordered = require("galore.lib.ordered")
local o = require("galore.opts")

local Saved = Buffer:new()

local function make_entry(self, db, box, search, name, exclude)
	local q = nm.create_query(db, search)
	if exclude then
		for _, ex in ipairs(self.opts.exclude_tags) do
			nm.query_add_tag_exclude(q, ex)
		end
	end
	local unread_q = nm.create_query(db, search .. " and tag:unread")
	local i = nm.query_count_messages(q)
	local unread_i = nm.query_count_messages(unread_q)
	table.insert(box, { i, unread_i, name, search})
end


function Saved.manual(manual)
	return function(self, searches)
		for search in ipairs(manual) do
			ordered.insert(searches, search.search, {search.search, search.name, false})
		end
	end
end

function Saved:gen_tags(searches)
	runtime.with_db(function (db)
		for tag in nm.db_get_all_tags(db) do
			local search = "tag:" .. tag
			ordered.insert(searches, search, {search, tag, true})
		end
	end)
end

function Saved:gen_internal(searches)
	for search in runtime.iterate_saved() do
		ordered.insert(searches, search, {search, search, true})
	end
end

function Saved:gen_excluded(searches)
	for _, tag in ipairs(self.opts.exclude_tags) do
		local search = "tag:" .. tag
		ordered.insert(searches, search, {search, tag, false})
	end
end


function Saved:get_searches()
	local searches = ordered.new()
	for _, gen in ipairs(self.searches) do
		gen(self, searches)
	end
	return searches
end

local function ppsearch(tag)
	local num, unread, name, search = unpack(tag)
	local left = string.format("%d(%d) %s", num, unread, name)
	return string.format("%-35s (%s)", left, search)
end

--- Redraw all the saved searches and update the count
function Saved:refresh()
	self:unlock()
	self:clear()
	local box = {}
	local searches = self:get_searches()
	runtime.with_db(function (db)
		for _, value in ordered.pairs(searches) do
			make_entry(self, db, box, value[1], value[2], value[3])
		end
	end)
	local formated = vim.tbl_map(ppsearch, box)
	self:set_lines(0, 0, true, formated)
	self:set_lines(-2, -1, true, {})
	self.State = box
	vim.api.nvim_win_set_cursor(0, {1,0})
	self:lock()
end

--- Return the currently selected line
function Saved:select()
	local line = vim.fn.line(".")
	return self.State[line]
end

--- Create a new window for saved searches
--- @param opts table {kind}
--- @return any
function Saved:create(opts, searches)
	o.saved_options(opts)
	return Buffer.create({
		name = opts.bufname,
		ft = "galore-saved",
		kind = opts.kind,
		cursor = "top",
		mappings = opts.key_bindings,
		init = function(buffer)
			buffer.searches = searches
			buffer.opts = opts
			buffer:refresh()
			opts.init(buffer)
		end,
	}, Saved)
end

return Saved
