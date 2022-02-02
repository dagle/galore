local config = require("galore.config")
local saved = require("galore.saved")
local cmp = require("galore.cmp")
local nu = require("galore.notmuch-util")
require("galore.gmime").init()

local galore = {}
function galore.open(opts)
	vim.fn.sign_define("uncollapsed", { text = "v" })
	vim.fn.sign_define("collapsed", { text = ">>" })
	galore.connect()
	return saved.create("replace")
end

function galore.connect(reconnect)
	if reconnect then
		galore.connected = false
	end
	if not galore.connected then
		nu.gen_config()
		if galore.config ~= nil then
			config.values = vim.tbl_deep_extend("keep", galore.config, config.values)
		end
	end
	galore.connected = true
end


-- should global functions try to connect?
function galore.setup(opts)
	galore.user_config = opts
	for bind, func in pairs(config.values.key_bindings.global) do
		vim.api.nvim_set_keymap("n", bind, func, { noremap = true, silent = true })
	end
end

return galore
