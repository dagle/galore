local config = require("galore.config")
local runtime = require("galore.runtime")
local nu = require("galore.notmuch-util")
require("galore.gmime.init").init()

-- vim.fn.sign_define("uncollapsed", { text = "v" })
-- vim.fn.sign_define("collapsed", { text = ">>" })

-- use setlocal and move this
-- vim.cmd("hi Folded guibg=None")
-- function _G.custom_fold_text()
-- 	local line = vim.fn.getline(vim.v.foldstart)
-- 	local line_count = vim.v.foldend - vim.v.foldstart + 1
-- 	return line
-- end
-- vim.opt.foldtext = 'v:lua.custom_fold_text()'
local galore = {}
function galore.open(opts)
	opts = opts or {}
	opts.open_mode = opts.open_mode or "replace"
	galore.connect()
	config.values.start(opts)
end

function galore.connect(reconnect)
	if reconnect then
		galore.connected = false
	end
	if not galore.connected then
		if galore.user_config ~= nil then
			config.values = vim.tbl_deep_extend("force", config.values, galore.user_config)
		end
		runtime.init()
		nu.gen_config()
	end
	galore.connected = true
end

function galore.setup(opts)
	-- Move this later
	vim.cmd("highlight nmVerifyGreen	ctermfg=224 guifg=Green")
	vim.cmd("highlight nmVerifyRed		ctermfg=224 guifg=Red")
	galore.user_config = opts
end

return galore
