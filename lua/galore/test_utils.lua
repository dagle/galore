local Job = require("plenary.job")
local galore =  require("galore")

local M = {}
-- lets do it like this for now
-- local test_path = (function()
-- 	local dirname = string.sub(debug.getinfo(1).source, 2, #"/test_utils.lua" * -1)
-- 	return dirname .. "/../../"
-- end)()


local test_path = os.getenv("GALORETESTDATA")

if not test_path then
	error("env GALORETESTDATA not set")
end

local script = test_path .. "/nm_init.sh"

function M.setup(testname)
	local config_path = test_path .. testname .. "/notmuch/notmuch-config"
	Job:new({
		command = script,
		args = {testname}
	}):sync()
	galore.setup({
		nm_config = config_path
	})
	galore.connect()
end

function M.cleanup(testname)
	local test = test_path .. testname
	vim.fn.delete(test, "rf")
end

function M.notmuch_random_message()
end

function M.gmime_random_message()
end

return M
