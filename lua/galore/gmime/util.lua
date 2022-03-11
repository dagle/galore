--- should we really include config?
local config = require("galore.config")
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

function M.make_id(message, prefix)
	local str = table.concat(u.collect(M.header_iter(message)))
	local sha = vim.fn.sha256(str)
	return prefix .. sha
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

function M.internet_address_list_iter(opt, str)
	-- local list = galore.internet_address_list_parse(opt, str)
	local list = gc.internet_address_list_parse(opt, str)
	if list == nil then
		return function ()
			return nil
		end
	end
	local i = 0
	return function()
		if i < gc.internet_address_list_length(list) then
			local addr = gc.internet_address_list_get_address(list, i)
			local mb = ffi.cast("InternetAddressMailbox *", addr)
			local email = gc.internet_address_mailbox_get_addr(mb)
			local name = gc.internet_address_get_name(addr)
			i = i + 1
			return name, email
		end
	end
end

function M.header_iter(message)
	local ls = go.object_get_header_list(ffi.cast("GMimeObject *", message))
	if ls then
		local j = gc.header_list_get_count(ls)
		local i = 0
		return function()
			if i < j then
				local header = gc.header_list_get_header_at(ls, i)
				local key = gc.header_get_name(header)
				local value = gc.header_get_value(header)
				i = i + 1
				return key, value
			end
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
		-- assert(false, "Empty path")
		return
	end
	local stream = gs.stream_file_open(path, "r")
	local parser = gs.parser_new_with_stream(stream)
	local message = gs.parser_construct_message(parser, nil)
	return message
end

--- XXX this should use
function M.save_part(part, filename)
	local stream = assert(gs.stream_file_open(filename, "w"), "can't open file: " .. filename)
	local content = gp.part_get_content(part)
	gs.data_wrapper_write_to_stream(content, stream)
	gs.stream_flush(stream)
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

local function sep(item, seperator)
	seperator = seperator or " "
	if item and item ~= "" then
		return item .. seperator
	end
	return item
end

function M.preview_addr(addr, minlen)
	local strbuf = {}
	for name, mail in M.internet_address_list_iter(nil, addr) do
		-- if the addr doesn't follow the mbox standard, we we nop
		if not (name and mail) then
			table.insert(strbuf, addr)
		else
			name = sanatize(name)
			local item = sep(name) .. "<" .. mail .. ">"
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
		local start = string.find(header, address)
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
	local from = get_backup(message, { "reply_to", "sender", "from" })
	if not type then
		from = gc.internet_address_list_to_string(from, nil, false)
		return {
			"To: " .. from,
			"From: " .. gc.internet_address_to_string(our, nil, false)
		}
	elseif type == "reply_all" then
		local to = gp.message_get_address(message, "to")
		append_no_dups(to, from)
		gc.internet_address_list_remove(to, our)

		local cc = gp.message_get_address(message, "cc")
		gc.address_list_remove(cc, our)

		local bcc = gp.message_get_address(message, "bcc")
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
