local Job = require("plenary.job")
local nm = require("galore.notmuch")

local M = {}
-- lets do it like this for now
local test_path = (function()
	local dirname = string.sub(debug.getinfo(1).source, 2, #"/test_utils.lua" * -1)
	return dirname .. "/../../tests/"
end)()

local script = test_path .. "nm_init.sh"

function M.setup(testname)
	local db_path = test_path .. testname .. "/mail/.notmuch"
	Job:new({
		command = script,
		args = {testname}
	}):sync()
	return nm.db_open(db_path, 0)
end

function M.cleanup(testname)
	local test = test_path .. testname
	vim.fn.delete(test, "rf")
end

function M.load_rawmessages()
end

return M
