-- view an attachment in a buffer if the file is considered viewable
-- maybe this should be called view-part and can be used for any part
local v = vim.api
local Buffer = require("galore.lib.buffer")
local gm = require("galore.gmime")
local u = require("util")
local M = {}

function M.create(attachment, kind, ft)
	M.state = attachment

	if M.attachment_view_buffer then
		M.attachment_view_buffer:focus()
		return
	end

	Buffer.create({
		name = "galore-attachment",
		ft = ft,
		kind = kind,
		cursor = "top",
		init = function(buffer)
			M.attachment_view_buffer = buffer
			local buf = gm.part_to_buf(attachment)
			local fixed = u.split_lines(buf)
			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, fixed)
			v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
		end,
	})
end
-- try to find a buffer first
