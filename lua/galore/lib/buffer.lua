local Buffer = {}

function Buffer:new(this)
	this = this or {}
	self.__index = self
	setmetatable(this, self)

	return this
end

function Buffer:focus()
	local windows = vim.fn.win_findbuf(self.handle)

	if #windows == 0 then
		vim.api.nvim_win_set_buf(0, self.handle)
		return
	end

	vim.fn.win_gotoid(windows[1])
end

function Buffer:lock()
	self:set_option("readonly", true)
	self:set_option("modifiable", false)
end

function Buffer:unlock()
	self:set_option("readonly", false)
	self:set_option("modifiable", true)
end

function Buffer:is_open()
	return #vim.fn.win_findbuf(self.handle) ~= 0
end

function Buffer:clear()
	vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {})
end

function Buffer:set_parent(parent)
	self.parent = parent
end

function Buffer:close(delete)
	if self.cleanup then
		self.cleanup(self)
	end
	if self.kind == "replace" and self.part then
		vim.api.nvim_win_set_buf(0, self.parent.handle)
	elseif self.kind == "floating" then
		vim.api.nvim_win_close(0, true)
		if self.parent then
			self.parent:focus()
		end
	else
		if self.parent then
			self.parent:focus()
		end
	end
	if delete then
		vim.api.nvim_buf_delete(self.handle, {})
	end
end

function Buffer:get_lines(first, last, strict)
	return vim.api.nvim_buf_get_lines(self.handle, first, last, strict)
end

function Buffer:get_line(line)
	return vim.fn.getbufline(self.handle, line)
end

function Buffer:get_current_line()
	return self:get_line(vim.fn.getpos(".")[2])
end

function Buffer:set_lines(first, last, strict, lines)
	vim.api.nvim_buf_set_lines(self.handle, first, last, strict, lines)
end

function Buffer:set_text(first_line, last_line, first_col, last_col, lines)
	vim.api.nvim_buf_set_text(self.handle, first_line, first_col, last_line, last_col, lines)
end

function Buffer:move_cursor(line)
	if line < 0 then
		self:focus()
		vim.cmd("norm G")
	else
		self:focus()
		vim.cmd("norm " .. line .. "G")
	end
end

function Buffer:is_valid()
	return vim.api.nvim_buf_is_valid(self.handle)
end

function Buffer:put(lines, after, follow)
	self:focus()
	vim.api.nvim_put(lines, "l", after, follow)
end

function Buffer:create_fold(first, last)
	vim.cmd(string.format(self.handle .. "bufdo %d,%dfold", first, last))
end

function Buffer:get_option(name)
	vim.api.nvim_buf_get_option(self.handle, name)
end

function Buffer:set_option(name, value)
	vim.api.nvim_buf_set_option(self.handle, name, value)
end

local function gen_name(num)
	if num == 1 then
		return "galore-saved"
	end
	return string.format("galore-saved-%d", num)
end

function Buffer:set_name(name)
	vim.api.nvim_buf_set_name(self.handle, name)
end

function Buffer:set_foldlevel(level)
	vim.cmd("setlocal foldlevel=" .. level)
end

function Buffer:replace_content_with(lines)
	self:set_lines(0, -1, false, lines)
end

-- XXX
function Buffer:open_fold(line, reset_pos)
	local pos
	if reset_pos == true then
		pos = vim.fn.getpos()
	end

	vim.fn.setpos(".", { self.handle, line, 0, 0 })
	vim.cmd("normal zo")

	if reset_pos == true then
		vim.fn.setpos(".", pos)
	end
end

function Buffer:add_highlight(line, col_start, col_end, name, ns_id)
	ns_id = ns_id or 0
	vim.api.nvim_buf_add_highlight(self.handle, ns_id, name, line, col_start, col_end)
end

function Buffer:unplace_sign(id)
	vim.cmd("sign unplace " .. id)
end

function Buffer:place_sign(line, name, group, id)
	-- Sign IDs should be unique within a group, however there's no downside as
	-- long as we don't want to uniquely identify the placed sign later. Thus,
	-- we leave the choice to the caller
	local sign_id = id or 1

	-- There's an equivalent function sign_place() which can automatically use
	-- a free ID, but is considerable slower, so we use the command for now
	local cmd = "sign place " .. sign_id .. " line=" .. line .. " name=" .. name
	if group ~= nil then
		cmd = cmd .. " group=" .. group
	end
	cmd = cmd .. " buffer=" .. self.handle

	vim.cmd(cmd)
	return sign_id
end

function Buffer:get_sign_at_line(line, group)
	group = group or "*"
	return vim.fn.sign_getplaced(self.handle, {
		group = group,
		lnum = line,
	})[1]
end

function Buffer:clear_sign_group(group)
	vim.cmd("sign unplace * group=" .. group .. " buffer=" .. self.handle)
end

function Buffer:set_filetype(ft)
	self:set_option("filetype", ft)
end

function Buffer:call(f)
	vim.api.nvim_buf_call(self.handle, f)
end

function Buffer.exists(name)
	return vim.fn.bufnr(name) ~= -1
end

function Buffer:set_extmark(...)
	return vim.api.nvim_buf_set_extmark(self.handle, ...)
end

function Buffer:get_extmark(ns, id)
	return vim.api.nvim_buf_get_extmark_by_id(self.handle, ns, id, { details = true })
end

function Buffer:del_extmark(ns, id)
	return vim.api.nvim_buf_del_extmark(self.handle, ns, id)
end

-- function Buffer:render()
-- 	if self.cache then
-- 		Buffer:set_lines(0, 0, true, self.cache)
-- 	end
-- 	self.cache = self:update()
-- end

function Buffer.create(config, class)
	config = config or {}
	local kind = config.kind or "split"
	local buffer = nil
	class = class or Buffer

	if kind == "replace" then
		vim.cmd("enew")
		buffer = class:new({handle = vim.api.nvim_get_current_buf()})
	elseif kind == "tab" then
		vim.cmd("tabnew")
		buffer = class:new({handle = vim.api.nvim_get_current_buf()})
	elseif kind == "split" then
		vim.cmd("below new")
		buffer = class:new({handle = vim.api.nvim_get_current_buf()})
	elseif kind == "split_above" then
		vim.cmd("top new")
		buffer = class:new({handle = vim.api.nvim_get_current_buf()})
	elseif kind == "vsplit" then
		vim.cmd("bot vnew")
		buffer = class:new({handle = vim.api.nvim_get_current_buf()})
	elseif kind == "floating" then
		-- Creates the border window
		local vim_height = vim.api.nvim_eval([[&lines]])
		local vim_width = vim.api.nvim_eval([[&columns]])
		local width = math.floor(vim_width * 0.8) + 5
		local height = math.floor(vim_height * 0.7) + 2
		local col = vim_width * 0.1 - 2
		local row = vim_height * 0.15 - 1

		local content_buffer = vim.api.nvim_create_buf(true, true)
		local content_window = vim.api.nvim_open_win(content_buffer, true, {
			relative = "editor",
			width = width,
			height = height,
			col = col,
			row = row,
			style = "minimal",
			focusable = false,
			border = "single"
		})

		vim.wo.winhl = "Normal:Normal"
		vim.api.nvim_win_set_cursor(content_window, { 1, 0 })
		buffer = Buffer:new({handle = content_buffer})
	else
		assert("Wrong buffer mode!")
	end

	buffer.kind = kind
	buffer.parent = config.parent
	buffer.cleanup = config.cleanup
	buffer.update = config.update

	vim.cmd("setlocal nonu")
	vim.cmd("setlocal nornu")

	buffer:set_name(config.name)

	buffer:set_option("buflisted", config.buflisted or false)
	buffer:set_option("bufhidden", config.bufhidden or "hide")
	buffer:set_option("buftype", config.buftype or "nofile")
	buffer:set_option("swapfile", false)
	-- don't want to do it like this
	vim.api.nvim_win_set_option(0, "wrap", false)

	if config.ft then
		buffer:set_filetype(config.ft)
	end

	local mapopts = { noremap = true, silent = true, buffer = buffer.handle}
	if config.mappings then
		for mode, val in pairs(config.mappings) do
			for key, cb in pairs(val) do
				local cbfunc = function()
					cb(buffer)
				end
				vim.keymap.set(mode, key, cbfunc, mapopts)
			end
		end
	else
		local conf = require("galore.config")
		for mode, val in pairs(conf.values.key_bindings.default) do
			for key, cb in pairs(val) do
				local cbfunc = function()
					cb(buffer)
				end
				vim.keymap.set(mode, key, cbfunc, mapopts)
			end
		end
	end

	if config.init then
		config.init(buffer)
	end

	if config.cursor == "top" then
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end

	-- if config.render then
	--   buffer.ui:render(unpack(config.render(buffer)))
	-- end

	--- BufDelete
	--- BufWipeout
	if config.autocmds then
		-- vim.api.nvim_create_augroup("") -- unique id?
		for event, cb in pairs(config.autocmds) do
			vim.api.nvim_create_autocmd(event, {callback = cb, buffer = buffer.handle})
		end
		-- for event, cb in pairs(config.autocmds) do
			-- buffer:define_autocmd(event, string.format("lua __BUFFER_AUTOCMD_STORE[%d]()", id))
		-- end
	end

	-- buffer.mmanager.register()

	if not config.modifiable then
		buffer:set_option("modifiable", false)
	end

	if config.readonly ~= nil and config.readonly then
		buffer:set_option("readonly", true)
	end

	-- buffer:call(function()
	--   local hl = vim.wo.winhl
	--   if hl ~= "" then
	--     hl = hl .. ","
	--   end
	--   vim.wo.winhl = hl .. "Folded:NeogitFold"
	-- end)

	return buffer
end

return Buffer
