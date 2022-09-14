local Buffer = require("galore.lib.buffer")
local o = require("galore.opts")
local async = require("plenary.async")
local browser = require("galore.browser")

local Mb = Buffer:new()

-- local function get_message(message, i, total)
-- 	local id = nm.message_get_id(message)
-- 	local sub = nm.message_get_header(message, "Subject")
-- 	local tags = u.collect(nm.message_get_tags(message))
-- 	local from = nm.message_get_header(message, "From")
-- 	local date = nm.message_get_date(message)
-- 	local matched = nm.message_get_flag(message, 0)
-- 	local excluded = nm.message_get_flag(message, 1)
-- 	return {
-- 		id = id,
-- 		level = 0,
-- 		-- pre = nil,
-- 		index = i,
-- 		total = total,
-- 		date = date,
-- 		from = from,
-- 		sub = sub,
-- 		tags = tags,
-- 		matched = matched,
-- 		excluded = excluded,
-- 	}
-- end
--
-- function Mb:get_messages(db, search)
-- 	self.State = {}
-- 	local lines = {}
-- 	local query = nm.create_query(db, search)
-- 	for _, ex in ipairs(self.opts.exclude_tags) do
-- 		nm.query_add_tag_exclude(query, ex)
-- 	end
-- 	local i = 1
-- 	local first = true
-- 	nm.query_set_sort(query, self.opts.sort)
--
-- 	for message in nm.query_get_messages(query) do
-- 		local line = get_message(message, 1, 1)
-- 		local formated = self.opts.show_message_description(line)
-- 		table.insert(lines, formated)
-- 		table.insert(self.State, line.id)
-- 		if self.maxlines and self.maxlines < i then
-- 			break
-- 		end
-- 		if i % 1000 == 0 then
-- 			self:set_lines(-1, -1, false, lines)
-- 			lines = {}
-- 			if first then
-- 				self:set_lines(0, 1, true, {})
-- 				first = false
-- 			end
-- 		end
-- 		i = i + 1
-- 	end
-- 	self:set_lines(-1, -1, false, lines)
-- 	if first then
-- 		self:set_lines(0, 1, true, {})
-- 	end
-- 	self:lock()
-- end

function Mb:tmb_search()
	local tmb = require("galore.thread_message_browser")
	local opts = o.bufcopy(self.opts)
	opts.parent = self
	tmb:create(self.search, opts)
end

local function mb_get(self)
	local first = true
	return browser.get_entries(self, "show-message", function (message)
		if message then
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
			-- 	table.insert(dias, diagnostics)
			-- end
			if first then
				vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {message.entry})
				first = false
			else
				vim.api.nvim_buf_set_lines(self.handle, -1, -1, false, {message.entry})
			end
			return 1
		end
	end)
end

function Mb:async_runner()
	local func = async.void(function ()
		local runner = mb_get(self)
		pcall(function ()
			runner.resume()
			self:lock()
		end)
	end)
	func()
end

function Mb:refresh()
	if self.runner then
		self.runner.close()
		self.runner = nil
	end
	self:unlock()
	self:clear()
	self:async_runner()
end

function Mb:update(line_nr)
	local id = self.State[line_nr]
	browser.update_lines_helper(self, "show-message", "id:"..id, line_nr)
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
	o.mb_options(opts)
	Buffer.create({
		name = opts.bufname(search),
		ft = "galore-browser",
		kind = opts.kind,
		cursor = "top",
		parent = opts.parent,
		mappings = opts.key_bindings,
		init = function(buffer)
			buffer.opts = opts
			buffer.search = search
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:refresh()
			buffer:commands()
			if opts.limit then
				browser.scroll(buffer)
			end
			opts.init(buffer)
		end,
	}, Mb)
end

return Mb
