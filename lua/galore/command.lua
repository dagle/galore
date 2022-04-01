local buf = require("galore.lib.buffer")
local Command = {}

function Command.current(func, ...)
	local bufid = vim.api.nvim_get_current_buf()
	local buffer = buf.get(bufid)
	if buffer then
		func(buffer, ...)
	else
		vim.notify("Current buffer not a galore buffer", vim.log.levels.ERROR)
	end
end

function Command.method(method, ...)
	local bufid = vim.api.nvim_get_current_buf()
	local buffer = buf.get(bufid)
	if buffer then
		buffer[method](buffer, ...)
	else
		vim.notify("Current buffer not a galore buffer", vim.log.levels.ERROR)
	end
end

-- :lua require("galore.command").current(require("galore.callback").change_tag)

return Command
