local Buffer = require("galore.lib.buffer")
local o = require("galore.opts")
local async = require("plenary.async")
local browser = require("galore.browser")

local Tmb = Buffer:new()

local function tmb_get(self)
	local first = true
	return browser.get_entries(self, "show-tree", function (thread)
		local i = 0
		for _, message in ipairs(thread) do
			table.insert(self.State, message.id)
			-- if message.matched then
			-- 	local diagnostics = {
			-- 		bufnr = self.handle,
			-- 		lnum = num-1,
			-- 		end_lnum = num-1,
			-- 		col = 0,
			-- 		end_col = 100,
			-- 		severity = vim.diagnostic.severity.INFO,
			-- 		message = "matched!",
			-- 		source = "galore",
			-- 	}
			-- 	table.insert(self.dias, diagnostics)
			-- end
			if first then
				vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {message.entry})
				first = false
			else
				vim.api.nvim_buf_set_lines(self.handle, -1, -1, false, {message.entry})
			end
			i = i + 1
		end
		-- We need to api for folds etc and 
		-- we don't want dump all off them like this
		-- but otherwise this works
		-- if #thread > 1 then
		-- 	local threadinfo = {
		-- 		stop = i-1,
		-- 		start = linenr,
		-- 	}
		-- 	table.insert(self.threads, threadinfo)
		-- end
		return i
	end)
end

function Tmb:async_runner()
	self.updating = true
	self.dias = {}
	self.threads = {}
	local func = async.void(function ()
		self.runner = tmb_get(self)
		-- self.runner = get_messages(self)
		pcall(function ()
			self.runner.resume(self.opts.limit)
			self:lock()
			self.updating = false;
		end)
	end)
	func()
end

function Tmb:mb_search()
	local mb = require("galore.message_browser")
	local opts = o.bufcopy(self.opts)
	opts.parent = self
	mb:create(self.search, opts)
end

--- Redraw the whole window
function Tmb:refresh()
	if self.runner then
		self.runner.close()
		self.runner = nil
	end
	self:unlock()
	self:clear()
	self:async_runner()
end

-- have an autocmd for refresh?
function Tmb:trigger_refresh()
	-- trigger an refresh in autocmd
end

function Tmb:update(line_nr)
	local id = self.State[line_nr]
	browser.update_lines_helper(self, "show-single-tree", "id:"..id, line_nr)
end

function Tmb:commands()
	vim.api.nvim_buf_create_user_command(self.handle, "GaloreChangetag", function (args)
		if args.args then
			local callback = require("galore.callback")
			callback.change_tag(self, args)
		end
	end, {
	nargs = "*",
	})
end

-- function Tmb:autocmd()

--- Create a browser grouped by threads
--- @param search string a notmuch search string
--- @param opts table
--- @return any
function Tmb:create(search, opts)
	o.tmb_options(opts)
	return Buffer.create({
		name = opts.bufname(search),
		ft = "galore-browser",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = opts.key_bindings,
		init = function(buffer)
			buffer.search = search
			buffer.opts = opts
			buffer.diagnostics = {}
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh(search)
			buffer:commands()
			if opts.limit then
				browser.scroll(buffer)
			end
			opts.init(buffer)
		end,
	}, Tmb)
end

return Tmb
