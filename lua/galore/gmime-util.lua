local g = require('galore.gmime')
local config = require('galore.config')
local u = require('galore.util')
local ffi = require('ffi')
local gm = require("galore.gmime")

local M = {}

-- get the ref if we are loading a draft
function M.get_ref(message)
	local ref_str = gm.object_get_header(ffi.cast("GMimeObject *", message), "References")
	local ref
	if ref_str then
		ref = gm.reference_parse(nil, ref_str)
	end
	local reply
	local reply_str = gm.g_mime_object_get_header(ffi.cast("GMimeObject *", message), "In-Reply-To")
	if reply_str then
		reply = gm.reference_parse(nil, ref_str)
	end
	return {
		reference = ref,
		in_reply_to = reply,
	}
end

-- make a new ref if we a making a reply
function M.make_ref(message)
  local ref_str = gm.object_get_header(ffi.cast("GMimeObject *", message), "References")
  local ref
  if ref_str then
    ref = gm.reference_parse(nil, ref_str)
  else
    ref = gm.new_ref()
  end
  local reply = nil
  local reply_str = gm.g_mime_object_get_header(ffi.cast("GMimeObject *", message), "Message-ID")
  if reply_str then
    reply = gm.reference_parse(nil, reply_str)
    gm.references_append(ref, reply_str)
  end
  return {
    reference = ref,
    in_reply_to = reply,
  }
  -- add old reply tail of refs
  -- add set
end

function M.viewable(part, control_bits)
	if gm.part_is_type(part, "text", "*") then
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
	for k, v in g.header_iter(message) do
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
	for _, v in g.header_iter(message) do
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
	for i, addr in g.addresses_iter(list) do
		for j, addr2 in g.addresses_iter(list) do
			local apa = g.address_to_string(addr)
			local bepa = g.address_to_string(addr2)
			if apa == bepa and i ~= j then
				table.insert(tbl, j)
			end
		end
	end
	--- FIXME dups in this one this too
	--- FIXME removing an index changes all other indexes
	for i in ipairs(tbl) do
		g.address_list_remove_at(list, i)
	end
end

local function get_list(message)
	local list = g.get_header(message, "List-Post")
	return list
end

-- local function a(f)
-- 	return g.show_addresses(f)
-- end

-- Get the first none-nil value in a list of fields
local function get_backup(message, list)
	for _, v in ipairs(list) do
		local addr = g.message_get_address(message, v)
		if addr ~= nil then
			if g.address_list_length(addr) > 0 then
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
function M.respone_headers(message, type)
	local our = M.get_from(message)
	local from = get_backup(message, {'reply_to', 'sender', 'from'})
	if not type then
		from = g.show_addresses(from)
		return {
			'To: ' .. from,
			'From: ' .. config.values.from_string(our),
		}
	elseif type == 'reply_all' then
		local to = g.message_get_address(message, 'to')
		g.address_list_append(to, from)
		g.address_list_remove(to, our)
		-- remove_dups(to)

		local cc = g.message_get_address(message, 'cc')
		g.address_list_remove(cc, our)
		-- remove_dups(cc)

		local bcc = g.message_get_address(message, 'bcc')
		g.address_list_remove(bcc, our)
		-- remove_dups(bcc)
		return {
			{'To: ', to},
			{'Cc: ', cc},
			{'Bcc: ', bcc},
			{'From: ', our}
		}
	elseif type == 'mailinglist' then
		local list = get_list()
		-- maybe return to sender?
		-- maybe reply_all? (list + to, cc: cc, bcc: bcc)
		return {
			{'To: ', list},
			{'From:', our}
		}
	end
	-- remove our from the list of to, cc, and bcc
	-- add from to the list of to
end

-- XXX not done
function M.forward(message, addr)
		local our = M.get_from(message)
		-- clean smtp headers
		-- clear cc and bcc
		-- clear from
		-- gm.message_add_mailbox(message, 'from', conf.values.name, our)

		local sub = gm.message_get_subject(message)
		sub = u.add_prefix(sub, "Fwd:")
		gm.message_set_subject(message, sub)
		-- set message to, to to
		local message_str = gm.write_message_mem(message)
	-- set the to addr
end

return M
