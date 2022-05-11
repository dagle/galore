--- should we really include config?
local config = require("galore.config")
local runtime = require("galore.runtime")
local gs = require("galore.gmime.stream")
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local go = require("galore.gmime.object")
local u = require("galore.util")
local ffi = require("ffi")

local M = {}

function M.insert_current_date(message)
	local time = os.time()
	gp.message_set_date(message, time)
end

function M.make_id(email)
	local fqdn = email:gsub(".*@", "")
	return gc.utils_generate_message_id(fqdn)
end

--- XXX move iters

function M.reference_iterator(ref)
	local i = 0
	return function()
		if i < gc.references_length(ref) then
			local ret = ffi.string(gc.references_get_message_id(ref, i))
			i = i + 1
			return ret
		end
		gc.references_clear(ref)
	end
end

function M.internet_address_list_iter_str(opt, str)
	local list = gc.internet_address_list_parse(opt, str)
	if list == nil then
		return function ()
			return nil
		end
	end
	return M.internet_address_list_iter(list)
end

-- Doesn't work with groups
function M.internet_address_list_iter(list)
	local i = 0
	return function()
		if i < gc.internet_address_list_length(list) then
			local addr = gc.internet_address_list_get_address(list, i)
			i = i + 1
			return addr
			-- local email = ""
			-- if gc.internet_address_is_mailbox(addr) then
			-- 	local mb = ffi.cast("InternetAddressMailbox *", addr)
			-- 	email = gc.internet_address_mailbox_get_addr(mb)
			-- end
			-- local name = gc.internet_address_get_name(addr)
			-- return name, email
		end
	end
end

--- XXX what to do when value is nil?
function M.header_iter(message)
	local ls = go.object_get_header_list(ffi.cast("GMimeObject *", message))
	if ls == nil then
		return function ()
			return nil
		end
	end
	local j = gc.header_list_get_count(ls)
	local i = 0
	return function()
		if i < j then
			local header = gc.header_list_get_header_at(ls, i)
			if header == nil then
				return nil, nil
			end
			local key = gc.header_get_name(header)
			local value = gc.header_get_value(header)
			-- do not do this, skip over
			if value == nil then
				value = ""
			end
			i = i + 1
			return key, value
		end
	end
end

function M.part_is_type(object, type, subtype)
	local content = go.object_get_content_type(object)
	return gc.content_type_is_type(content, type, subtype)
end

function M.part_mime_type(object)
	local ct = go.object_get_content_type(object)
	local type = gc.content_type_get_mime_type(ct)
	return type
end

--- @param path string
--- @return gmime.Message
function M.parse_message(path)
	if not path or path == "" then
		return nil
	end
	local stream, err = gs.stream_file_open(path, "r")
	local parser = gs.parser_new_with_stream(stream)
	local message = gs.parser_construct_message(parser, runtime.parser_opts)
	return message, err
end

local function number_of_parts(filename)
	local message = M.parse_message(filename)
	local part = gp.message_get_mime_part(message)
	if not gp.is_partial(part) then
		return nil
	end
	local partial = ffi.cast("GMimeMessagePartial *", part)
	return gp.message_partial_get_total(partial)
end

--- @param filenames string[]
--- @return gmime.Message
function M.construct(filenames)
	if #filenames == 1 then
		local message = M.parse_message(filenames[1])
		return message
	end
	local parts = {}
	local messages = {} -- ugly hack
	for _, filename in ipairs(filenames) do
		local message = M.parse_message(filename)
		if message == nil then
			return nil
		end
		local part = gp.message_get_mime_part(message)
		if not gp.is_partial(part) then
			return nil
		end
		local partial = ffi.cast("GMimeMessagePartial *", part)
		table.insert(messages, message)
		table.insert(parts, partial)
	end
	local num = number_of_parts(filenames[1])
	if num ~= #filenames then
		vim.notify("More parts than files", vim.log.levels.ERROR)
		--- this isn't implemented
		--- we need to search the emails if this isn't the case
	end
	return gp.message_partial_reconstruct_message(parts, #filenames)
end

function M.write_message(path, object)
	local stream, err = gs.stream_file_open(path, "w+")
	if err == nil and stream ~= nil then
		go.object_write_to_stream(object, runtime.format_opts, stream)
		gs.stream_flush(stream)
	end
	return err
end


--- XXX this should be async
function M.save_part(part, filename)
	local stream = assert(gs.stream_file_open(filename, "w"), "can't open file: " .. filename)
	local content = gp.part_get_content(part)
	gs.data_wrapper_write_to_stream(content, stream)
	gs.stream_flush(stream)
end

function M.part_to_buf(part)
	local dw = gp.part_get_content(part)
	local stream = gs.stream_mem_new()
	gs.data_wrapper_write_to_stream(dw, stream)
	return M.mem_to_string(stream)
end


function M.mem_to_string(mem)
	local array = gs.stream_mem_get_byte_array(ffi.cast("GMimeStreamMem *", mem))
	return ffi.string(array.data, array.len)
end

function M.is_multipart_alt(object)
	local type = M.part_mime_type(object)
	if type == "multipart/alternative" then
		return true
	end
	return false
end

function M.get_ref(message)
	local ref_str = go.object_get_header(ffi.cast("GMimeObject *", message), "References")
	local ref
	if ref_str then
		ref = gc.references_parse(runtime.parser_opts, ref_str)
	end
	local reply
	local reply_str = go.object_get_header(ffi.cast("GMimeObject *", message), "In-Reply-To")
	if reply_str then
		reply = gc.references_parse(runtime.parser_opts, ref_str)
	end
	return {
		References = ref,
		["In-Reply-To"] = reply,
	}
end

-- make a new ref if we a making a reply
function M.make_ref(message)
	local ref_str = go.object_get_header(ffi.cast("GMimeObject *", message), "References")
	local ref
	if ref_str then
		ref = gc.references_parse(runtime.parser_opts, ref_str)
	else
		ref = gc.references_new()
	end
	local reply = nil
	local reply_str = go.object_get_header(ffi.cast("GMimeObject *", message), "Message-ID")
	if reply_str then
		reply = gc.references_parse(runtime.parser_opts, reply_str)
		gc.references_append(ref, reply_str)
	end
	return {
		References = ref,
		["In-Reply-To"] = reply,
	}
end

local function sanatize(name)
	return string.gsub(name, " via.*", "")
end

local function sep(item, seperator)
	seperator = seperator or " "
	if item and item ~= "" then
		return item .. seperator
	end
	return item
end

function M.preview_addr(addr, minlen)
	local strbuf = {}
	for paddr in M.internet_address_list_iter_str(runtime.parser_opts, addr) do
		local email = ""
		if gc.internet_address_is_mailbox(paddr) then
			local mb = ffi.cast("InternetAddressMailbox *", paddr)
			email = gc.internet_address_mailbox_get_addr(mb)
		end
		local name = gc.internet_address_get_name(paddr)
		if not (name and email) then
			table.insert(strbuf, addr)
		else
			name = sanatize(name)
			local item = sep(name) .. "<" .. email .. ">"
			table.insert(strbuf, item)
		end
	end
	local str = table.concat(strbuf, " ")
	local len = vim.fn.strchars(str)
	str = str .. string.rep(" ", minlen - len)
	return str
end

local function match_address(header, addresses)
	for _, address in ipairs(addresses) do
		if header:match(address) then
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
	for k, v in M.header_iter(message) do
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
	for _, v in M.header_iter(message) do
		local addr = match_address(v, emails)
		if addr then
			return addr
		end
	end
	return config.values.primary_email
end

local function get_list(message)
	return go.object_get_header(ffi.cast("GMimeObject *", message), "List-Post")
end

-- Get the first none-nil value in a list of fields
local function get_to(message, headers)
	for _, v in ipairs(headers) do
		local addr = gp.message_get_address(message, v)
		if addr ~= nil then
			if gc.internet_address_list_length(addr) > 0 then
				return addr
			end
		end
	end
	return nil
end

--- XXX we are comparing pointers etc
local function append_no_dups(dst, src)
	for _, semail in M.internet_address_list_iter(src) do
		local matched = false
		for _, demail in M.internet_address_list_iter(dst) do
			if semail == demail and semail then
				matched = true
				break;
			end
		end
		if not matched then
			gc.internet_address_list_add(dst, semail)
		end
	end
end

-- XXX maybe this shouldn't return strings but rather a message
-- That way we can move this to templates

-- Generate a header for the response
-- Depending on the mode it will:
-- Removes our address as reciever
-- Adds our address to sender
-- Adds sender to the reciving list
-- Removes any dups
--- @param message gmime.Message
--- @param type string what kind of reply mode we use
function M.respone_headers(message, type)
	local addr = M.get_from(message)
	local our = gc.internet_address_mailbox_new(config.values.name, addr)
	local from = get_to(message, { "reply_to", "sender", "from" })
	if not type then
		from = gc.internet_address_list_to_string(from, runtime.format_opts, false)
		return {
			"To: " .. from,
			"From: " .. gc.internet_address_to_string(our, runtime.format_opts, false)
		}
	elseif type == "reply_all" then
		local to = gp.message_get_address(message, "to")
		append_no_dups(to, from)
		gc.internet_address_list_remove(to, our)

		local cc = gp.message_get_address(message, "cc")
		gc.internet_address_list_remove(cc, our)

		return {
			{ "From: ", gc.internet_address_to_string(our, runtime.format_opts, false)},
			{ "To: ", gc.internet_address_list_to_string(to, runtime.format_opts, false)},
			{ "Cc: ", gc.internet_address_list_to_string(cc, runtime.format_opts, false)},
		}
	elseif type == "mailinglist" then
		local list = get_list(message)
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

local function unbracket()
end

function M.smart_response(message)
	local list = get_list(message)
	if list ~= nil then
		M.respone_headers(message, "mailinglist")
	end
end

function M.Unsubscribe(message)
	local unsub = go.object_get_header(ffi.cast("GMimeObject *", message), "List-Post")
	local resp = gp.new_message(true)

	gp.message_add_mailbox(resp, "to", "", unsub)
	-- send(message)
end

function M.Subscribe()
end

function M.ListHelp()
end

function M.OpenArchive()
end

--- generate a fortward message
--- make to_str optional?
-- Use the resent headers instead?
-- resent-date     =       "Resent-Date:" date-time
-- resent-from     =       "Resent-From:" mailbox-list
-- resent-sender   =       "Resent-Sender:" mailbox
-- resent-to       =       "Resent-To:" address-list
-- resent-cc       =       "Resent-Cc:" address-list
-- resent-bcc      =       "Resent-Bcc:" (address-list / [CFWS]) CRLF
-- resent-msg-id   =       "Resent-Message-ID:" msg-id CRLF
function M.forward(message, to_str)
	local addr = M.get_from(message)
	local new_subject = "FWD: " .. gp.message_get_subject(message)

	local new = gp.new_message(true)
	gp.message_add_mailbox(new, "from", config.values.name, addr)

	local list = gc.internet_address_list_parse(runtime.parser_opts, to_str)
	local address = gp.message_get_address(new, "to")
	if not list then
		vim.notify("Couldn't parse to address", vim.log.levels.ERROR)
		return
	end
	gc.internet_address_list_append(address, list)

	M.insert_current_date(new)
	gp.message_set_subject(new, new_subject, nil)

	local date = gp.message_get_date(message)
	local from = gc.internet_address_list_to_string(
		gp.message_get_from(message), runtime.format_opts, false)
	local to = gc.internet_address_list_to_string(
		gp.message_get_to(message), runtime.format_opts, false)

	local body = gp.message_get_body(message)
	local text = gp.text_part_get_text(body)
	local fwd = "---- Forward Message ----\n"
	fwd = string.format("%s ---- Original sent the %s from %s to %s ----\n",
	      fwd, os.date("%x", date), from, to)
	fwd = fwd .. text
	local new_plain = gp.text_part_new_with_subtype("plain")
	gp.text_part_set_text(new_plain, fwd)
	return new
end

function M.forward_resent(message, to_str)
	local addr = M.get_from(message)
	go.object_set_header(message, "Resent-From", addr, nil)
	go.object_set_header(message, "Resent-To", to_str, nil)

	local time = os.time()
	local gdate = gmime.g_date_time_new_from_unix_local(time)
	local date_str = gc.utils_header_format_date(gdate)
	go.object_set_header(message, "Resent-Date", date_str, nil)
	gmime.g_date_time_unref(gdate)
end

return M
