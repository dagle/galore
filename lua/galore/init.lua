local config = require("galore.config")
local runtime = require("galore.runtime")
local nu = require("galore.notmuch-util")
require("galore.gmime.init").init()

-- vim.fn.sign_define("uncollapsed", { text = "v" })
-- vim.fn.sign_define("collapsed", { text = ">>" })
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
	for bind, func in pairs(config.values.key_bindings.global) do
		vim.keymap.set("n", bind, func, { noremap = true, silent = true})
	end
end

return galore
