local nm = require("galore.notmuch")

local M = {}
-- lets do it like this for now
-- local db_path = (function()
-- 	local dirname = string.sub(debug.getinfo(1).source, 2, #"/gmime.lua" * -1)
-- 	return dirname .. "/../../tests/data/.notmuch"
-- end)()

local path = "/home/dagle/code/galore/tests/data/"
local db_path = path .. ".notmuch"


M.db_path = db_path

-- should make a testconfig
function M.setup()
	-- make directory
	vim.fn.mkdir(db_path, "")
	local db = nm.db_create(db_path)
	return db
end

-- load all testing emails into the db
function M.load_messages()
end

-- load all gmime test messages (doesn't use nm)
function M.load_rawmessages()
end

-- function M.cleanup()
-- 	vim.fn.delete(db_path, flags: any)
-- 	-- delete db_path
-- end

return M
