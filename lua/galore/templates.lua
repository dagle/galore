local gu = require("galore.gmime-util")

local r = require("galore.render")
local config = require("galore.config")
local runtime = require("galore.runtime")
local u = require("galore.util")
local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

local M = {}

local function addrlist_parse(str)
	local ialist = gmime.InternetAddressList.parse(runtime.parser_opts, str)
	return ialist
end

-- TODO, make things more composable
-- Atm we overwrite all the headers instead of merging them
-- Maybe we should reparse the message before we pass,
-- that way we don't have to worry about destorying it

-- TODO move helper functions that could be useful for outside of this file

-- Get the first none-nil value in a list of fields
--- Can use non-standard fields
local function get_backup(message, list)
	for _, v in ipairs(list) do
		local addr = message:get_addresses(v)
		if addr ~= nil and addr:length(addr) > 0 then
			return addr
		end
	end
	return nil
end

local function remove(list, addr)
	local i = 0
	for demail in gu.internet_address_list_iter(list) do
		if gu.address_equal(demail, addr) then
			list:remove_at(i)
			return true
		end
		i = i + 1
	end
	return false
end

local function append_no_dup(addr, dst)
	local matched = gu.ialist_contains(addr, dst)
	if not matched then
		dst:add(addr)
	end
end

local function PP(list)
	return list:to_string(nil, false)
end

local function pp(ia)
	return ia:to_string(nil, false)
end

local function safelist(...)
	local list = {}
	for i=1, select("#",...) do
		local value = select(i,...)
		if value then
			table.insert(list, value)
		end
	end
	return list
end

local function issubscribed(addresses)
	local str = table.concat(config.values.mailinglist_subscribed, ", ")
	local list = gmime.InternetAddressList.parse(runtime.parser_opts, str)
	for v in gu.internet_address_list_iter(list) do
		if gu.ialist_contains(v, addresses) then
			return true
		end
	end
end

local function get_key(gpg_id)
	local ctx = gmime.GpgContext.new()
	local mem = gmime.StreamMem.new()
	ctx:export_keys({gpg_id}, mem)
	return mem:get_byte_array()
end

function M.compose_new(opts)
	local headers = opts.headers or {}
	local our = gmime.InternetAddressMailbox.new(config.values.name, config.values.primary_email)
	headers.From = pp(our)

	opts.headers = headers
end

function M.mailkey(opts, gpg_id)
	local attachments = opts.attachments or {}
	gpg_id = gpg_id or config.values.gpg_id
	local key = get_key(gpg_id)
	table.insert(attachments,
		{filename = "opengpg_pubkey.asc", data = key, mime_type = "application/pgp-keys"})
	opts.attach = attachments
end

function M.load_body(message, opts)
	local bufrender = r.new({
		verify = false,
	}, r.default_render)
	local buffer = {}
	local state = r.render_message(bufrender, message, buffer, opts)
	opts.Body = buffer
	opts.Attach = state.attachments
end

function M.load_headers(message, opts)
	opts = opts or {}
	local headers = {}
	for k, v in gu.header_iter(message) do
		headers[k] = v
	end
	opts.headers = headers
end

function M.subscribed(old_message)
	local to = old_message:get_to(old_message)
	local cc = old_message:get_cc(old_message)
	if issubscribed(to) or issubscribed(cc) then
		return true
	end
end

--- TODO clean up mft stuff
function M.mft_response(old_message, opts, type)
	local headers = opts.headers or {}
	if not type or type == "author" then
		local from = get_backup_header(old_message, { "Mail-Reply-To", "reply_to", "from", "sender" })
		headers.To = from
	elseif type == "reply_all" then
		local mft = old_message:get_header("Mail-Followup-To")
		if mft ~= nil then
			local ialist = gmime.InternetAddressList.parse(runtime.parser_opts, mft)
			headers.To = PP(ialist)
		else
			M.response_message(old_message, opts, type)
		end
	end
	opts.headers = headers
end

function M.mft_insert(opts)
	local headers = opts.headers
	headers["Mail-Reply-To"] = opts.headers["Reply-To"]
	local to = addrlist_parse(headers.To)
	local cc = addrlist_parse(headers.Cc)
	if issubscribed(to) or issubscribed(cc) then
		--- should we remove look and remove dups?
		--- because an address could be in both to and cc
		headers["Mail-Followup-To"] = table.concat(safelist(headers.To, headers.Cc), ",")
	end
	opts.headers = headers
end

function M.mft_insert_notsubbed(old_message, opts)
	local headers = opts.headers
	headers["Mail-Reply-To"] = opts.headers["Reply-To"]
	local to = addrlist_parse(headers.To)
	local cc = addrlist_parse(headers.Cc)
	local ml = old_message:get_header("List-Post")
	if ml ~= nil and not (issubscribed(to) or issubscribed(cc)) then
		ml = PP(ml)
		headers["Mail-Followup-To"] = table.concat(safelist(headers.From, ml), ",")
	end
	opts.headers = headers
end

function M.smart_response(old_message, opts, backup_type)
	local ml = old_message:get_header("List-Post")
	if ml then
		M.response_message(old_message, opts, "mailinglist")
		return
	end
	M.response_message(old_message, opts, backup_type)
end


function M.response_message(old_message, opts, type)
	local at = gmime.AddressType
	local headers = opts.headers or {}

	local addr = gu.get_our_email(old_message)
	local our = gmime.InternetAddressMailbox.new(config.values.name, addr)
	local our_str = pp(our)

	local sub = old_message:get_subject()
	headers.Subject = u.add_prefix(sub, "Re:")

	headers.From = our_str

	local from = get_backup(old_message, { at.REPLY_TO, at.FROM,  at.SENDER}):get_address()
	if not type or type == "reply" then
		headers.To = pp(from)
	elseif type == "reply_all" then
		--- these are destructive
		local to = old_message:get_addresses(at.TO)
		append_no_dup(from, to)
		remove(to, our)
		headers.To = PP(to)

		local cc = old_message:get_addresses(at.CC)
		remove(to, our)
		headers.Cc = PP(cc)

		local bcc = old_message:get_addresses(at.BCC)
		remove(to, our)
		headers.Bcc = PP(bcc)
	elseif type == "mailinglist" then
		local ml = old_message:get_header("List-Post")
		headers.To = u.unmailto(ml)
	end
	opts.headers = headers
end

function M.forward_resent(old_message, to_str, opts)
	local at = gmime.AddressType
	local headers = opts.headers or {}

	local addr = gu.get_our_email(old_message)
	local our = gmime.InternetAddressMailbox.new(config.values.name, addr)
	local our_str = pp(our)
	headers.From = our_str

	local sub = old_message:get_subject()
	sub = u.add_prefix(sub, "FWD:")
	headers.Subject = sub

	headers.To = to_str

	opts.headers = headers

	headers["Resent-To"] = PP(old_message:get_address(at.TO))
	headers["Resent-From"] = PP(old_message:get_address(at.FROM))
	headers["Resent-Cc"] = PP(old_message:get_address(at.CC))
	headers["Resent-Bcc"] = PP(old_message:get_address(at.BCC))
	headers["Recent-Date"] = old_message:get_date()
	headers["Recent-Id"] = old_message:get_message_id()
	-- insert before the body
	table.insert(opts.Body, 1, {"--- Forwarded message ---"})
	opts.headers = headers
end

function M.bounce(old_message, opts)
	local at = gmime.AddressType
	local from = get_backup(old_message, { at.REPLY_TO, at.FROM,  at.SENDER}):get_address(0)
	M.forward_resent(old_message, from, opts)

	local sub = old_message:get_subject()
	sub = u.add_prefix(sub, "Return:")
	opts.headers.Subject = sub
	table.remove(opts.Body, 1)
	table.insert(opts.Body, 1, {"--- This email isn't for me ---"})
	opts.attachments = {} -- do not bounce the attachments
end

function M.Resent(old_message, opts)
	local at = gmime.AddressType
	local headers = opts.headers or {}

	headers.To = PP(old_message:get_address(at.TO))
	headers.From = PP(old_message:get_address(at.FROM))
	headers.Cc = PP(old_message:get_address(at.CC))
	headers.Bcc = PP(old_message:get_address(at.BCC))
	headers.Subject = old_message:get_subject()

	opts.headers = headers
end

function M.subscribe(old_message, opts)
	local unsub = old_message:get_header("List-Subscribe")
	if unsub == nil then
		error("Subscribe header not found")
		return
	end
	local addr = gu.get_our_email(old_message)
	local headers = opts.headers or {}
	headers.From = {config.values.name, addr}
	headers.To = u.unmailto(unsub)
	headers.Subject = "Subscribe"
	opts.headers = headers
end

function M.unsubscribe(old_message, opts)
	local unsub = old_message:get_header("List-Unsubscribe")
	if unsub == nil then
		error("Unsubscribe header not found")
		return
	end
	local addr = gu.get_our_email(old_message)
	local headers = opts.headers or {}
	headers.From = {config.values.name, addr}
	headers.To = u.unmailto(unsub)
	headers.Subject = "Unsubscribe"
	opts.headers = headers
end

return M
