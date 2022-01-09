-- local v = vim.api

-- for k,v in pairs(package.loaded) do
-- 	if string.find(k, "galore.") then
-- 		package.loaded[k] = nil
-- 	end
-- end

-- package.loaded["ffi"] = nil
local config = require('galore.config')
local saved = require('galore.saved')
local compose = require('galore.compose')
local jobs = require('galore.jobs')
local cmp = require('galore.cmp')
local nu = require('galore.notmuch-util')
local tele = require('galore.telescope')
require('galore.gmime').init()

local db_path = os.getenv("HOME") .. '/mail'
-- vim.api.nvim_set_keymap('n', '<leader>mc', '<cmd>lua require("galore.compose").create("tab")<CR>', {noremap = true, silent = true})

local galore = {
	-- saved = saved,
	open = function (opts)
		-- idk about this stuff
		-- if opts ~= nil then
		-- 	local window = require("notmuch.window." .. opts)
		-- 	if window ~= nil then
		-- 		window.create()
		-- 	else
		-- 		error("no window module called " .. opts)
		-- 	end
		-- end
		saved.create("current")
		-- create tab etc
	end,
	setup = function (opts)
		nu.gen_config()
		if opts ~= nil then
			config.values = vim.tbl_deep_extend("keep", opts, config.values)
		end
	end,
}

galore.setup()
-- tele.load_draft()
-- galore.open()
-- compose.create('tab')
-- t.notmuch_search({search = "tag:inbox"})

return galore
