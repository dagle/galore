local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local config = require("galore.config")
local Buffer = require("galore.lib.buffer")
local runtime = require("galore.runtime")
local dia = require("galore.diagnostics")

local Mb = Buffer:new()

function Mb:get_messages(db, search)
	local state = {}
	local query = nm.create_query(db, search)
	for _, ex in ipairs(config.values.exclude_tags) do
		nm.query_add_tag_exclude(query, ex)
	end
	for message in nm.query_get_messages(query) do
		table.insert(state, nu.get_message(message))
	end
	self.State = state
end

function Mb:ppMessage(messages)
	local box = {}
	for _, message in ipairs(messages) do
		local formated = config.values.show_message_description(message)
		table.insert(box, formated)
	end
	self:set_lines(-1, -1, true, box)
	self:set_lines(0, 1, true, {})
end

function Mb:refresh()
	self:unlock()
	self:clear()
	runtime.with_db(function (db)
		self:get_messages(db, self.search)
	end)
	self:ppMessage(self.State)
	self:lock()
end

--- move these
function Mb:update(start)
	local message = self.State[start]
	local formated = config.values.show_message_description(message)
	self:unlock()
	self:set_lines(start-1, start, true, {formated})
	self:lock()
end

function Mb:commands()
	vim.api.nvim_buf_create_user_command(self.handle, "GaloreChangetag", function (args)
		if args.args then
			local callback = require("galore.callback")
			callback.change_tag(self, args)
		end
	end, {
	nargs = "*",
	})
end

-- create a browser class
function Mb:create(search, opts)
	Buffer.create({
		name = "galore-messages: " .. search,
		ft = "galore-threads",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = config.values.key_bindings.message_browser,
		init = function(buffer)
			buffer.search = search
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh()
			dia.set_emph(buffer, config.values.default_emph)
			buffer:commands()
			config.values.bufinit.message_browser(buffer)
		end,
	}, Mb)
end

return Mb
