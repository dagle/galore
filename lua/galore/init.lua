local config = require("galore.config")
local started = false

local galore = {}
function galore.open(opts)
	opts = opts or {}
	opts.kind = opts.kind or "replace"
	galore.connect()
	config.values.init(opts)
end

function galore.connect(reconnect)
	if reconnect then
		galore.connected = false
	end
	local runtime = require("galore.runtime")
	local def = require("galore.default")
	if not started then
		require("galore.gmime.init").init()
	end
	if not galore.connected then
		def.gen_config()
		if galore.user_config ~= nil then
			config.values = vim.tbl_deep_extend("force", config.values, galore.user_config)
		end
		runtime.init()
	end
	galore.connected = true
	started = true
end

local function colors()
	vim.api.nvim_set_hl(0, "GaloreVerifyGreen", {fg="Green"})
	vim.api.nvim_set_hl(0, "GaloreVerifyRed", {fg="Red"})
	vim.api.nvim_set_hl(0, "GaloreSeperator", {fg="Red"})
	vim.api.nvim_set_hl(0, "GaloreAttachment", {fg="Red"})
	vim.api.nvim_set_hl(0, "GaloreHeader", {fg="Red"})
end

function galore.setup(opts)
	-- Move this later
	colors()
	galore.user_config = opts
end

function galore.withconnect(func, ...)
	if not galore.connected then
		galore.connect()
	end
	func(...)
end

function galore.compose(args, kind)
	local opts = {}
	if type(args) == "string" then
		args = args:gsub("mailto:", "")
		if string.gmatch(args, "?") then
			local lp = args:gsub(".*?", "")
			for k, v in string.gmatch(lp, "([^&=?]+)=([^&=?]+)" ) do
				opts[k] = v
			end
		end
		opts.mailto = args:gsub("?.*", "")
	end
	if not galore.connected then
		galore.connect()
	end
	galore.withconnect(function (...)
	local comp = require('galore.compose')
	comp:create(kind, ...)
	end, nil, nil, opts)
end

--- setup things like
--- galore.desktop
--- xdg-mime?
--- autocrypt?
function galore.configure()
	vim.fn.system('xdg-mime default galore.desktop "x-scheme-handler/mailto"')
	-- vim.ui.input({prompt="Setup autoconfig?"}, function(choice)
	-- 	if not choice then
	-- 		return
	-- 	end
	-- 	choice = choice:lower()
	-- 	if choice == "yes" or  choice == "y" then
	-- 		require("galore.autocrypt").init()
	-- 	end
	-- end)
end

return galore
