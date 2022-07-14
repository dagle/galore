-- local gs = require("galore.gmime.stream")
-- local convert = require("galore.gmime.convert")
-- local ffi = require("ffi")
local M = {}

--- Adds the attachments in the bottom of the buffer
function M.render_attachments(attachments, buf)
	local marks = {}
	for k, _ in pairs(attachments) do
		local str = string.format("-[%s]", k)
		table.insert(marks, {str, "GaloreAttachment"})
	end
	local line = vim.fn.line("$") - 1
	local opts = {
		virt_lines = {
			marks
		},
		-- virt_lines_above = true,
	}
	buf:set_extmark(buf.ns, line, 0, opts)
end

function M.exmark(buf, ns, style, text, line)
	-- for now
	if not ns then
		return
	end
	line = line or vim.fn.line("$") - 1
	local opts = {
		virt_lines = {
			{{text, style}}
		},
	}
	vim.api.nvim_buf_set_extmark(buf, ns, line, 0, opts)
end

return M
