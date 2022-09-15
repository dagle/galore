local M = {}

--- Adds the attachments in the bottom of the buffer
function M.render_attachments(attachments, line, buffer, ns)
	if #attachments == 0 then
		return
	end
	local marks = {}
	for _, v in ipairs(attachments) do
		local str = string.format("- [%s]", v.filename)
		table.insert(marks, {str, "GaloreAttachment"})
	end
	local opts = {
		virt_lines = {
			marks
		},
	}
	vim.api.nvim_buf_set_extmark(buffer, ns, line, 0, opts)
end

function M.extmark(buf, ns, style, text, line)
	-- for now
	if not ns then
		return
	end
	local opts = {
		virt_lines = {
			{{text, style}}
		},
	}
	vim.api.nvim_buf_set_extmark(buf, ns, line, 0, opts)
end

return M
