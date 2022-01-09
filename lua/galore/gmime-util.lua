local g = require('galore.gmime')
local config = require('galore.config')

local M = {}

local function contains(tbl, key)
	for _, v in ipairs(tbl) do
		if v == key then
			return true
		end
	end
	return false
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
-- XXX Horrible
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
		if contains(tbl, k) then
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
	-- return
end

-- local function a(f)
-- 	return g.show_addresses(f)
-- end

local function get_backup(message, list)
	for _, v in ipairs(list) do
		local addr = g.message_get_address(message, v)
		if addr == nil then
			return nil
		end
		-- check the length instead?
		if g.address_list_length(addr) > 0 then
			return addr
		end
	end
	return nil
end


-- Generate a header for the response
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

return M
