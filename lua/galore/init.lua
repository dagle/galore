local config = require("galore.config")

local galore = {}

galore.connected = false

function galore.open(opts)
	opts = opts or {}
	galore.withconnect(function ()
		config.values.init(opts)
	end)
end

function galore.connect()
	local runtime = require("galore.runtime")
	local lgi = require 'lgi'
	local gmime = lgi.require("GMime", "3.0")
	gmime.init()
	if not galore.connected then
		if galore.user_config ~= nil then
			config.values = vim.tbl_deep_extend("force", config.values, galore.user_config)
		end
		runtime.init()
	end
	galore.connected = true
end

function galore.setup(opts)
	galore.user_config = opts
end

function galore.withconnect(func)
	if not galore.connected then
		galore.connect()
	end
	func()
end

function galore.compose(kind)
	galore.withconnect(function ()
		local cb = require('galore.callback')
		cb.new_message(kind)
	end)
end

function galore.mailto(kind, str)
	local url = galore("galore.url")
	str = str:gsub("<%s*(.*)%s*>", "%1")
	local opts = url.parse_url(str)

	-- remove things we don't trust in a mailto
	opts = url.normalize(opts)
	galore.withconnect(function ()
		local cb = require('galore.callback')
		cb.new_message(kind, opts)
	end)
end

function galore.xdg_install()
	local dirname = string.sub(debug.getinfo(1).source, 2, #"/init.lua" * -1)
	local str = dirname .. "../../" .. "xdg_install.sh"
	vim.fn.system(str)
end

return galore
