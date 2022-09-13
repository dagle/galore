--- A hook takes a message and returns a boolean if success

local gp = require("galore.gmime.parts")
local go = require("galore.gmime.object")
local config = require("galore.config")
local job = require("galore.jobs")
local ffi = require("ffi")

local M = {}

-- A pre hook is always return a boolean. If a pre hook return false

-- maybe move this here
-- function M.mark_read(parent, line_info, vline)
-- 	runtime.with_db_writer(function (db)
-- 		config.values.tag_unread(db, line_info.id)
-- 		nu.tag_if_nil(db, line_info, config.values.empty_tag)
-- 		nu.update_line(db, parent, line_info, vline)
-- 	end)
-- end

--- @param message gmime.Message
--- @return boolean
local function has_attachment(message)
	local state = {}
	local find_attachment = function (_, part, _)
		if gp.is_part(part) and gp.part_is_attachment(part) then
			state.attachment = true
		end
	end
	gp.message_foreach(message, find_attachment)
	return state.attachment
end

--- Pre sending, check for attachments
--- @param message gmime.Message
--- @return boolean
function M.missed_attachment(message)
	local sub = gp.message_get_subject(message)
	local start, _ = string.find(sub, "[a,A]ttachment")
	local re, _ = string.find(sub, "^%s*Re:")
	if start and not re and not has_attachment(message) then
		return false
	end
	return true
end

--- Pre sending, ask if you want to send the email
--- Should be in general be inserted before IO functions (like FCC)
--- @return boolean
function M.confirm()
	local ret = false
	vim.ui.input({
		prompt = "Wanna send email? Y[es]",
	}, function (input)
		if input then
			input = input:lower()
			if input == "yes" or "y" then
				ret = true
			end
		end
	end)
	return ret
end

-- XXX do error handling.
--- Pre send, insert the mail into fcc dir and then remove FCC header
--- This is relative to your maildir
--- @param message  gmime.Message
--- @return boolean
function M.fcc_nm_insert(message)
	local obj = ffi.cast("GMimeObject *", message)
	local fcc_str = go.object_get_header(obj, "FCC")
	go.object_remove_header(obj, "FCC")

	-- Should we try to guard users?
	-- this shouldn't be an abs path
	local path = config.values.fccdir .. "/" .. fcc_str

	job.insert_mail(message, path, "")
end

--- write file to a maildir
--- this should do a lot more checks
--- create dirs etc if it doesn't exist

--- Pre send, insert the mail into fcc dir and then remove FCC header
--- @param message 
--- @return boolean
function M.fcc_fs(message)
	local obj = ffi.cast("GMimeObject *", message)
	local fcc_str = go.object_get_header(obj, "FCC")
	go.object_remove_header(obj, "FCC")
end

function M.preview()
end

---

function M.delete_draft()
end

return M
