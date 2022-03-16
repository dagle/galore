local gu = require("galore.gmime.util")
local gc = require("galore.gmime.content")
local gp = require("galore.gmime.parts")
local go = require("galore.gmime.object")
local config = require("galore.config")
local ffi = require("ffi")

local M = {}

--- should have an "easy" mode to make templates

local function get_list(message)
	return go.object_get_header(ffi.cast("GMimeObject *", message), "List-Post")
end

-- Get the first none-nil value in a list of fields
local function get_backup(message, list)
	for _, v in ipairs(list) do
		local addr = gp.message_get_address(message, v)
		if addr ~= nil then
			if gc.internet_address_list_length(addr) > 0 then
				return addr
			end
		end
	end
	return nil
end

--- Does this move pointers instead of copying data? Because moving pointers
--- Won't work, maybe we need to create new mailboxes etc
local function append_no_dups(dst, src)
	for _, semail in M.internet_address_list_iter(src) do
		local matched = false
		for _, demail in M.internet_address_list_iter(dst) do
			if semail == demail then
				matched = true
				break;
			end
		end
		if not matched then
			gc.internet_address_list_add(dst, semail)
		end
	end
end

--- STUB
function M.response_message(message, old_message, type)
	local addr = gu.get_from(old_message)
	local our = gc.internet_address_mailbox_new(config.values.name, addr)
	local from = get_backup(old_message, { "reply_to", "sender", "from" })
	if not type then
		from = gc.internet_address_list_to_string(from, nil, false)
		return {
			"To: " .. from,
			"From: " .. gc.internet_address_to_string(our, nil, false)
		}
	elseif type == "reply_all" then
		local old_to = gp.message_get_address(old_message, "to")
		local to = gp.message_get_address(message, "to")
		append_no_dups(to, old_to)
		append_no_dups(to, from)
		gc.internet_address_list_remove(to, our)

		local cc_old = gp.message_get_address(old_message, "cc")
		local cc = gp.message_get_address(message, "cc")
		append_no_dups(cc, cc_old)
		gc.address_list_remove(cc, our)

		local bcc_old = gp.message_get_address(old_message, "bcc")
		local bcc = gp.message_get_address(message, "bcc")
		append_no_dups(bcc, bcc_old)
		gc.address_list_remove(bcc, our)
		return {
			{ "From: ", gc.internet_address_to_string(our, nil, false)},
			{ "To: ", gc.internet_address_list_to_string(to, nil, false)},
			{ "Cc: ", gc.internet_address_list_to_string(cc, nil, false)},
			{ "Bcc: ", gc.internet_address_list_to_string(bcc, nil, false)},
		}
	elseif type == "mailinglist" then
		local list = get_list()
		-- maybe return to sender?
		-- maybe reply_all? (list + to, cc: cc, bcc: bcc)
		return {
			{ "To: ", list },
			{ "From:", our },
		}
	end
	-- remove our from the list of to, cc, and bcc
	-- add from to the list of to
end

return M
