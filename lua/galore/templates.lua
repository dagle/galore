local gu = require("galore.gmime.util")
local gc = require("galore.gmime.content")
local gp = require("galore.gmime.parts")
local go = require("galore.gmime.object")
local config = require("galore.config")
local runtime = require("galore.runtime")
local ffi = require("ffi")
local gmime = require("galore.gmime.gmime_ffi")

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

local function append_no_dups(dst, src)
	local add = {}
	for _, semail in gu.internet_address_list_iter(src) do
		local matched = false
		for _, demail in gu.internet_address_list_iter(dst) do
			if semail == demail then
				matched = true
				break;
			end
		end
		if not matched then
			table.insert(add, semail)
		end
	end
	for _, semail in ipairs(add) do
		gc.internet_address_list_add(dst, semail)
	end
end

--- instead of copying the body, we just reference it
function M.set_body_ref(message, old_message)
	local object = gp.message_get_mime_part(old_message)
	gp.message_set_mime_part(message, object)
end

function M.default_template()
	local message = gp.new_message(true)
	return message
end

function M.compose_new(message, mailto)
	local our = gc.internet_address_mailbox_new(config.values.name, config.values.primary_email)

	if mailto then
		local tolist = gp.message_get_address(message, "to")
		local to = gc.internet_address_mailbox_new(mailto[1], mailto[2])
		append_no_dups(tolist, to)
	end

	local fromlist = gp.message_get_address(message, "from")
	append_no_dups(fromlist, our)
	return message
end

function M.response_message(message, old_message, type)
	M.set_body_ref(message, old_message)
	local addr = gu.get_from(old_message)
	local our = gc.internet_address_mailbox_new(config.values.name, addr)
	local from = get_backup(old_message, { "reply_to", "from", "sender" }) -- ORDER?
	if not type then
		local tolist = gp.message_get_address(message, "to")
		append_no_dups(tolist, from)

		local fromlist = gp.message_get_address(message, "from")
		append_no_dups(fromlist, our)

		return message
	elseif type == "reply_all" then
		local old_to = gp.message_get_address(old_message, "to")
		local to = gp.message_get_address(message, "to")
		append_no_dups(to, old_to)
		append_no_dups(to, from)
		-- should we do this?
		gc.internet_address_list_remove(to, our)

		local cc_old = gp.message_get_address(old_message, "cc")
		local cc = gp.message_get_address(message, "cc")
		append_no_dups(cc, cc_old)
		gc.address_list_remove(cc, our)

		local bcc_old = gp.message_get_address(old_message, "bcc")
		local bcc = gp.message_get_address(message, "bcc")
		append_no_dups(bcc, bcc_old)
		gc.address_list_remove(bcc, our)

		return message
	elseif type == "mailinglist" then
		-- TODO
		return message
		-- local list = get_list()
		-- maybe return to sender?
		-- maybe reply_all? (list + to, cc: cc, bcc: bcc)
		-- return {
		-- 	{ "To: ", list },
		-- 	{ "From:", our },
		-- }
	end
	-- remove our from the list of to, cc, and bcc
	-- add from to the list of to
end

return M
