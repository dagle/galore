local gu = require("galore.gmime.util")
local gs = require("galore.gmime.stream")
local ge = require("galore.gmime.crypt")
local gc = require("galore.gmime.content")
local gp = require("galore.gmime.parts")
local go = require("galore.gmime.object")
local config = require("galore.config")
local runtime = require("galore.runtime")
local r = require("galore.render")
local ffi = require("ffi")
local u = require("galore.util")
local builder = require("galore.builder")

local M = {}

local function addrlist_parse(str)
	return gc.internet_address_list_parse(nil, str)
end

-- TODO, make things more composable
-- Atm we overwrite all the headers instead of merging them
-- Maybe we should reparse the message before we pass,
-- that way we don't have to worry about destorying it

-- TODO move helper functions that could be useful for outside of this file

local function get_list(message)
	local list = go.object_get_header(ffi.cast("GMimeObject *", message), "List-Post")
	return list
end

-- Get the first none-nil value in a list of fields
--- Can use non-standard fields
local function get_backup(message, list)
	-- for _, item in ipairs(list) do
	-- 	local header = go.object_get_header(ffi.cast("GMimeObject *", message), item)
	-- 	if header ~= nil then
	-- 		local addr = addrlist_parse(header)
	-- 		if addr ~= nil then
	-- 			return addr
	-- 		end
	-- 	end
	-- end
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

local function remove(list, addr)
	local i = 0
	for demail in gc.internet_address_list_iter(list) do
		if gu.address_equal(demail, addr) then
			gc.internet_address_list_remove_at(list, i)
			return true
		end
		i = i + 1
	end
	return false
end

local function append_no_dup(addr, dst)
	local matched = gu.ialist_contains(addr, dst)
	if not matched then
		gc.internet_address_list_add(dst, addr)
	end
end

local function PP(list)
	return gc.internet_address_list_to_string(list, nil, false)
end

local function pp(ia)
	return gc.internet_address_to_string(ia, nil, false)
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
	local list = gc.internet_address_list_parse(runtime.parser_opts, str)
	for v in gc.internet_address_list_iter(list) do
		if gu.ialist_contains(v, addresses) then
			return true
		end
	end
end

local function get_key(gpg_id)
	local ctx = ge.gpg_context_new()
	local mem = gs.stream_mem_new()
	ge.crypto_context_export_keys(ctx, {gpg_id}, mem)
	return gu.mem_to_string(mem)
end

function M.compose_new(opts)
	local headers = opts.headers or {}
	local our = gc.internet_address_mailbox_new(config.values.name, config.values.primary_email)
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
	local object = ffi.cast("GMimeObject *", message)
	local headers = {}
	for k, v in gu.header_iter(object) do
		headers[k] = v
	end
	opts.headers = headers
end

--- TODO clean up mft stuff
function M.subscribed(old_message)
	local to = gp.message_get_to(old_message)
	local cc = gp.message_get_cc(old_message)
	if issubscribed(to) or issubscribed(cc) then
		return true
	end
end

function M.mft_response(old_message, opts, type)
	local headers = opts.headers or {}
	if not type or type == "author" then
		local from = get_backup(old_message, { "Mail-Reply-To", "reply_to", "from", "sender" })
		headers.To = from
	elseif type == "reply_all" then
		local mft = go.object_get_header(ffi.cast("GMimeObject *", message), "Mail-Followup-To")
		if mft ~= nil then
			local ialist = gc.internet_address_list_parse(runtime.parser_opts, mft)
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
	local ml = get_list(old_message)
	if ml ~= nil and not (issubscribed(to) or issubscribed(cc)) then
		ml = PP(ml)
		headers["Mail-Followup-To"] = table.concat(safelist(headers.From, ml), ",")
	end
	opts.headers = headers
end

function M.smart_response(old_message, opts, backup_type)
	local list = get_list(old_message)
	if list then
		M.response_message(old_message, opts, "mailinglist")
		return
	end
	M.response_message(old_message, opts, backup_type)
end


function M.response_message(old_message, opts, type)
	local headers = opts.headers or {}

	local addr = gu.get_our_email(old_message)
	local our = gc.internet_address_mailbox_new(config.values.name, addr)
	local our_str = pp(our)

	local sub = gp.message_get_subject(old_message)
	headers.Subject = u.add_prefix(sub, "Re:")

	headers.From = our_str
	--- should you set this if it's the same as from?
	-- headers["Reply-To"] = our_str

	local from = gu.addr_head(get_backup(old_message, { "reply_to", "from", "sender" }))
	if not type or type == "reply" then
		headers.To = pp(from)
	elseif type == "reply_all" then
		--- these are destructive
		local to = gp.message_get_address(old_message, "to")
		append_no_dup(from, to)
		remove(to, our)
		headers.To = PP(to)

		local cc = gp.message_get_address(old_message, "cc")
		remove(to, our)
		headers.Cc = PP(cc)

		local bcc = gp.message_get_address(old_message, "bcc")
		remove(to, our)
		headers.Bcc = PP(bcc)
	elseif type == "mailinglist" then
		local list = get_list(old_message)
		headers.To = u.unmailto(list)
	end
	opts.headers = headers
end

function M.forward_resent(old_message, to_str, opts)
	local headers = opts.headers or {}

	local addr = gu.get_our_email(old_message)
	local our = gc.internet_address_mailbox_new(config.values.name, addr)
	local our_str = pp(our)
	headers.From = our_str

	local sub = gp.message_get_subject(old_message)
	sub = u.add_prefix(sub, "FWD:")
	headers.Subject = sub

	headers.To = to_str

	opts.headers = headers

	headers["Resent-To"] = PP(gp.message_get_address(old_message, "To"))
	headers["Resent-From"] = PP(gp.message_get_address(old_message, "From"))
	headers["Resent-Cc"] = PP(gp.message_get_address(old_message, "Cc"))
	headers["Resent-Bcc"] = PP(gp.message_get_address(old_message, "Bcc"))
	headers["Recent-Date"] = gp.message_get_subject(old_message)
	headers["Recent-Id"] = gp.message_get_message_id(old_message)
	table.insert(opts.Body, {"--- Forwarded message ---"})
	opts.headers = headers
end

function M.bounce(old_message, opts)
	local from = get_backup(old_message, { "reply_to", "from", "sender" })
	M.forward_resent(old_message, from, opts)

	local sub = gp.message_get_subject(old_message)
	sub = u.add_prefix(sub, "Return:")
	opts.headers.Subject = sub
	table.remove(opts.Body, 1)
	table.insert(opts.Body, {"--- This email isn't for me ---"})
	opts.attachments = {} -- do not bounce the attachments
end

function M.Resent(old_message, opts)
	local headers = opts.headers or {}

	headers.To = PP(gp.message_get_address(old_message, "To"))
	headers.From = PP(gp.message_get_address(old_message, "From"))
	headers.Cc = PP(gp.message_get_address(old_message, "Cc"))
	headers.Bcc = PP(gp.message_get_address(old_message, "Bcc"))
	headers.Subject = gp.message_get_subject(old_message)

	opts.headers = headers
end

function M.subscribe(old_message, opts)
	local unsub = go.object_get_header(ffi.cast("GMimeObject *", old_message), "List-Subscribe")
	if unsub == nil then
		error("Subscribe header not supported")
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
	local unsub = go.object_get_header(ffi.cast("GMimeObject *", old_message), "List-Unsubscribe")
	if unsub == nil then
		error("Unsubscribe header not supported")
		return
	end
	local addr = gu.get_our_email(old_message)
	local headers = opts.headers or {}
	headers.From = {config.values.name, addr}
	headers.To = u.unmailto(unsub)
	headers.Subject = "Unsubscribe"
	opts.headers = headers
end

function M.send_template(opts)
	local buf = {headers=opts.headers, body=opts.Body}
	local send_opts = {}
	local message = builder.create_message(buf, send_opts, opts.Attach, {}, builder.textbuilder)
	-- something like this
	-- job.send_mail(message, function ()
	-- end
end

return M
