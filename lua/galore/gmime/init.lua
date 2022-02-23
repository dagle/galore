local M = {}

local galore = require("galore.gmime.gmime_ffi")

function M.init()
	galore.g_mime_init()
	galore.g_mime_filter_reply_module_init()
end

return M
