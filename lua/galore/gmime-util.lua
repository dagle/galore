local config = require("galore.config")
local u = require("galore.util")
local ffi = require("ffi")
local gu = require("galore.gmime.util")
-- local gmime = require("galore.gmime")
local go = require("galore.gmime.object")
local gc = require("galore.gmime.content")
local gp = require("galore.gmime.parts")

local M = {}

function M.forward(message, addr)
	local our = M.get_from(message)
	local old = {
		From = gp.message_get_address(message, "from"),
		To = gp.message_get_address(message, "to"),
		Cc = gp.message_get_address(message, "cc"),
		Bcc = gp.message_get_address(message, "bcc"),
		Date = gp.message_get_address(message, "date"),
	    Subject = gp.message_get_subject(message)
	}
	-- XXX clear all headers

	-- this is wrong
	local name, email = gc.internet_address_list(nil, our)
	gmime.message_add_mailbox(message, "from", name, email)
	name, email = gmime.internet_address_list(nil, addr)
	gmime.message_add_mailbox(message, "to", name, email)

	local sub = u.add_prefix(old.Subject, "Fwd:")
	gmime.message_set_subject(message, sub)

	local string_builder = {}
	local header = "---------- Forwarded message ---------"

	table.insert(string_builder, header)
	for k,v in pairs(old) do
		table.insert(string_builder, k .. ": " .. v)
	end

	--- XXX maybe do these later
	local string = table.concat(string_builder, "\n")
	-- M.message_add_marker(message, string)
end

return M
