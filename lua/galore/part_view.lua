-- view an attachment in a buffer if the file is considered viewable
-- maybe this should be called view-part and can be used for any part
local v = vim.api
local Buffer = require("galore.lib.buffer")
local gm = require("galore.gmime")
local M = {}

local Pv = Buffer:new()

function M.create(part, name, ft, kind)
	Buffer.create({
		name = name,
		ft = ft,
		kind = kind or "floating",
		cursor = "top",
		init = function(buffer)
			M.attachment_view_buffer = buffer
			local buf = gm.part_to_buf(part)
			local fixed = vim.split(buf, "\n", false)
			buffer:set_lines(0, 0, true, fixed)
			buffer:set_lines(-2, -1, true, {})
		end,
	}, Pv)
end

return M
-- try to find a buffer first
