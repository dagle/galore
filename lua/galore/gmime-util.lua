local config = require("galore.config")
local u = require("galore.util")
local ffi = require("ffi")
local gu = require("galore.gmime.util")
-- local gmime = require("galore.gmime")
local go = require("galore.gmime.object")
local gc = require("galore.gmime.content")
local gp = require("galore.gmime.parts")

local M = {}

function M.insert_current_date(message)
	local time = gmime.time_now()
	gmime.message_set_date(message, time)
end

function M.make_id(message, prefix)
	local str = table.concat(u.collect(gmime.header_iter(message)))
	local sha = vim.fn.sha256(str)
	return prefix .. sha
end

-- get the ref if we are loading a draft
--- fix this, we convert to string and back
--- Write a getter to object->header?
function M.get_ref(message)
	local ref_str = go.object_get_header(ffi.cast("GMimeObject *", message), "References")
	local ref
	if ref_str then
		ref = gc.references_parse(nil, ref_str)
	end
	local reply
	local reply_str = go.object_get_header(ffi.cast("GMimeObject *", message), "In-Reply-To")
	if reply_str then
		reply = gc.references_parse(nil, ref_str)
	end
	return {
		reference = ref,
		in_reply_to = reply,
	}
end

--- @param message any
--- @return boolean
function M.has_attachment(message)
	local find_attachment = function (_, part, state)
		if gp.is_part(part) and gp.part_is_attachment(part) then
			state.attachment = true
		end
	end
	local state = {}
	gp.message_foreach(message, find_attachment, state)
	return state.attachment
end

--- Doesn't handle re:
function M.missed_attachment(message)
	local sub = gp.message_get_subject(message)
	local start, _ = string.find(sub, "[a,A]ttachment")
	if start and not M.has_attachment(message) then
		return false
	end
	return true
end

-- make a new ref if we a making a reply
function M.make_ref(message)
	local ref_str = go.object_get_header(ffi.cast("GMimeObject *", message), "References")
	local ref
	if ref_str then
		ref = gc.references_parse(nil, ref_str)
	else
		ref = gc.references_new()
	end
	local reply = nil
	local reply_str = go.object_get_header(ffi.cast("GMimeObject *", message), "Message-ID")
	if reply_str then
		reply = gc.references_parse(nil, reply_str)
		gc.references_append(ref, reply_str)
	end
	return {
		reference = ref,
		in_reply_to = reply,
	}
end

local function sanatize(name)
	return string.gsub(name, " via.*", "")
end

function M.preview_addr(addr, minlen)
	local strbuf = {}
	for name, mail in gu.internet_address_list_iter(nil, addr) do
		name = sanatize(name)
		local item = name .. " <" .. mail .. ">"
		table.insert(strbuf, item)
	end
	local str = table.concat(strbuf, " ")
	local len = vim.fn.strchars(str)
	str = str .. string.rep(" ", minlen - len)
	return str
end

-- This should be be able to be customized
-- Because what might not be viewable for some, might be for others
function M.viewable(part, control_bits)
	-- gmime.part.part_is_type
	if gmime.part_is_type(part, "text", "*") then
		return true
	end
	--
	-- if can_decrypt(part, control_bits) then
	-- 	return true
	-- end
	-- if it's encrypted return true if we can decrypt it
end

local function match_address(header, addresses)
	for _, address in ipairs(addresses) do
		local start, stop = string.find(header, address)
		if start then
			return address
		end
	end
	return nil
end

-- get what email addr we used to recieve this email
-- useful if you have multiple emails
-- So if you reply to an email,
-- Quite horrible but can't be done in nice way?
function M.get_from(message)
	local emails = {}
	table.insert(emails, config.values.primary_email)
	for _, m in ipairs(config.values.other_email) do
		table.insert(emails, m)
	end
	local tbl = {
		"Delivered-To",
		"To",
		"Cc",
		"Bcc",
		"Envelope-to",
		"X-Original-To",
	}
	for k, v in gu.header_iter(message) do
		if u.contains(tbl, k) then
			local addr = match_address(v, emails)
			if addr then
				return addr
			end
		end
	end
	if not config.values.guess_email then
		return config.values.primary_email
	end
	for _, v in gu.header_iter(message) do
		local addr = match_address(v, emails)
		if addr then
			return addr
		end
	end
	return config.values.primary_email
end

-- should return a new list
-- shouldn't we just use a table instead?
local function remove_dups(list)
	local tbl = {}
	for i, addr in gmime.addresses_iter(list) do
		for j, addr2 in gmime.addresses_iter(list) do
			local string_addr = gmime.address_to_string(addr)
			local string_addr2 = gmime.address_to_string(addr2)
			if string_addr == string_addr2 and i ~= j then
				table.insert(tbl, j)
			end
		end
	end
	--- FIXME dups in this one this too
	--- FIXME removing an index changes all other indexes
	for i in ipairs(tbl) do
		gmime.address_list_remove_at(list, i)
	end
end

local function get_list(message)
	local list = gmime.get_header(message, "List-Post")
	return list
end

-- local function a(f)
-- 	return g.show_addresses(f)
-- end

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

-- Generate a header for the response
-- Depending on the mode it will:
-- Removes our address as reciever
-- Adds our address to sender
-- Adds sender to the reciving list
-- Removes any dups
--- @param message gmessage
--- @param type string what kind of reply mode we use
function M.respone_headers(message, type)
	local our = M.get_from(message)
	local from = get_backup(message, { "reply_to", "sender", "from" })
	if not type then
		from = gc.internet_address_list_to_string(from, nil, false)
		return {
			"To: " .. from,
			"From: " .. config.values.from_string(our),
		}
	elseif type == "reply_all" then
		local to = gp.message_get_address(message, "to")
		gc.address_list_append(to, from)
		gc.address_list_remove(to, our)
		-- remove_dups(to)

		local cc = gp.message_get_address(message, "cc")
		gc.address_list_remove(cc, our)
		-- remove_dups(cc)

		local bcc = gp.message_get_address(message, "bcc")
		gc.address_list_remove(bcc, our)
		-- remove_dups(bcc)
		return {
			{ "To: ", to },
			{ "Cc: ", cc },
			{ "Bcc: ", bcc },
			{ "From: ", our },
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

-- Do hmt in the future, left for blank now
local function hmtl_marker(str)
	-- return '<div>---------- Forwarded message ---------<br></div>'
end

function M.message_add_marker(message, str)
	local function marker_fun(obj, part, state)
		if not gmime.part_is_attachment(part) then
			local ct = gmime.get_content_type(part)
			local type = gmime.get_mime_type(ct)
			if type == "text/plain" then
				-- update the part?
			end
		end
	end
	gmime.message_foreach(message, marker_fun, depth)
	-- local part = gm.mime_part(message)
	-- if gm.is_part(part) then
	-- elseif gm.is_multipart(part) then
	-- -- gm.is_multipart_alt(part) then
	-- -- end
	-- end
end

function M.forward(message, addr)
	local our = M.get_from(message)
	local old = {
		From = gmime.message_get_address(message, "from"),
		To = gmime.message_get_address(message, "to"),
		Cc = gmime.message_get_address(message, "cc"),
		Bcc = gmime.message_get_address(message, "bcc"),
		Date = gmime.message_get_address(message, "date"),
	    Subject = gmime.message_get_subject(message)
	}
	-- XXX clear all headers

	local name, email = gmime.internet_address_list(nil, our)
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
