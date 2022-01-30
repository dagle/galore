-- local v = vim.api

-- for k,v in pairs(package.loaded) do
-- 	if string.find(k, "galore.") then
-- 		package.loaded[k] = nil
-- 	end
-- end

-- package.loaded["ffi"] = nil
local config = require('galore.config')
local saved = require('galore.saved')
-- local compose = require('galore.compose')
-- local jobs = require('galore.jobs')
local cmp = require('galore.cmp')
local nu = require('galore.notmuch-util')
require('galore.gmime').init()

local galore = {
	-- saved = saved,
	open = function (opts)
		vim.fn.sign_define("uncollapsed", {text="v"})
		vim.fn.sign_define("collapsed", {text=">>"})
		-- idk about this stuff
		-- if opts ~= nil then
		-- 	local window = require("notmuch.window." .. opts)
		-- 	if window ~= nil then
		-- 		window.create()
		-- 	else
		-- 		error("no window module called " .. opts)
		-- 	end
		-- end
		return saved.create("replace")
		-- create tab etc
	end,
	setup = function (opts)
		nu.gen_config()
		if opts ~= nil then
			config.values = vim.tbl_deep_extend("keep", opts, config.values)
		end

		for bind, func in pairs(config.values.key_bindings.global) do
			vim.api.nvim_set_keymap('n', bind, func, { noremap=true, silent=true })
		end
	end,
}

return galore
