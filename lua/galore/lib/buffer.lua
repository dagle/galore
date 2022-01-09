local v = vim.api
local M = {}
M.mt = {}

function M:new(handle)
	local this = {
		handle = handle,
		kind = nil,
		ref = nil,
	}
	setmetatable(this, M.mt)
	M.mt.__index = M
	return this
end

function M:focus()
	local win = vim.fn.win_findbuf(self.handle)
	if #win == 0 then
		v.nvim_win_set_buf(0, self.handle)
		return
	end

	vim.fn.win_gotoid(win[1])
end

function M:is_open()
	return #vim.fn.win_findbuf(self.handle) ~= 0
end

function M:clear()
  vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {})
end

function M:set_ref(ref)
	self.ref = ref
end

function M:close(delete)
	if self.kind == "current" then
		v.nvim_win_set_buf(0, self.ref.handle)
	else
		if self.ref then
			self.ref:focus()
		end
	end
	if delete then
		v.nvim_buf_delete(self.handle, {})
	end
end


function M.create(config)
	config = config or {}
	local kind = config.kind or "split"
	local buffer = nil

	if kind == "tab" then
		vim.cmd("tabnew")
		buffer = M:new(vim.api.nvim_get_current_buf())
	elseif kind == "current" then
		-- buffer = M:new(vim.api.nvim_get_current_buf())
		buffer = M:new(v.nvim_create_buf(false, true))
		v.nvim_win_set_buf(0, buffer.handle)
	elseif kind == "split" then
		vim.cmd("below new")
		buffer = M:new(vim.api.nvim_get_current_buf())
	elseif kind == "vsplit" then
		vim.cmd("top vnew")
		buffer = M:new(vim.api.nvim_get_current_buf())
	end
	buffer.kind = kind
	buffer.ref = config.ref -- config could be {}
	v.nvim_buf_set_option(buffer.handle, "buflisted", config.buflisted or false)
	v.nvim_buf_set_option(buffer.handle, "bufhidden", config.bufhidden or "hide")
	v.nvim_buf_set_option(buffer.handle, "buftype", config.buftype or "nofile")
	v.nvim_buf_set_option(buffer.handle, "swapfile", config.swapfile or false)

	v.nvim_buf_set_name(buffer.handle, config.name)

	if config.ft then
		vim.bo.filetype = config.ft
	end

	if config.init then
		config.init(buffer)
	end

	if config.cursor == "top" then
		v.nvim_win_set_cursor(0, { 1, 0 })
	end

	----
	if not config.modifiable then
		vim.api.nvim_buf_set_option(buffer.handle, "modifiable", false)
	end

	if config.readonly ~= nil and config.readonly then
		vim.api.nvim_buf_set_option(buffer.handle, "readonly", true)
	end
	return buffer
end

return M
