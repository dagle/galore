-- XXX CLEAN UP! XXX
-- XXX (Not needed!) Missing: Part-iter, stream-gio
-- TODO sort enums!

-- XXX Maybe these files:
-- Filter, crypto, parts, stream, ...
local M = {}

local galore = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

function M.init()
	galore.g_mime_init()
	galore.g_mime_filter_reply_module_init()
end

function M.stream_reset(stream)
	galore.g_mime_stream_reset(stream)
end

--- XXX DONE
function M.part_is_attachment(part)
	return galore.g_mime_part_is_attachment (part)
end

--- XXX DONE
function M.mime_part(message)
	return galore.g_mime_message_get_mime_part(message)
end

function M.get_disposition(obj)
	local tmp = galore.g_mime_object_get_disposition(obj)
	if tmp == nil then
		return nil
	end
	return ffi.string(tmp)
end

function M.message_get_date(message)
	local data = galore.g_mime_message_get_date(message)
	return tonumber(galore.g_date_time_to_unix(data))
end

--- XXX DONE
-- should we tolower the type?
function M.message_get_address(message, type)
	local ctype
	if type == "sender" then
		ctype = galore.GMIME_ADDRESS_TYPE_SENDER
	elseif type == "from" then
		ctype = galore.GMIME_ADDRESS_TYPE_FROM
	elseif type == "reply_to" then
		ctype = galore.GMIME_ADDRESS_TYPE_REPLY_TO
	elseif type == "to" then
		ctype = galore.GMIME_ADDRESS_TYPE_TO
	elseif type == "cc" then
		ctype = galore.GMIME_ADDRESS_TYPE_CC
	elseif type == "bcc" then
		ctype = galore.GMIME_ADDRESS_TYPE_BCC
	end
	local list = galore.g_mime_message_get_addresses(message, ctype)
	return list
end

-- void internet_address_list_clear (InternetAddressList *list);
-- int internet_address_list_add (InternetAddressList *list, InternetAddress *ia);

--
-- void internet_address_list_prepend (InternetAddressList *list, InternetAddressList *prepend);
-- void internet_address_list_insert (InternetAddressList *list, int index, InternetAddress *ia);
--
-- gboolean internet_address_list_contains (InternetAddressList *list, InternetAddress *ia);
-- int internet_address_list_index_of (InternetAddressList *list, InternetAddress *ia);
--
-- InternetAddress *internet_address_list_get_address (InternetAddressList *list, int index);
-- void internet_address_list_set_address (InternetAddressList *list, int index, InternetAddress *ia);
--
-- void internet_address_list_encode (InternetAddressList *list, GMimeFormatOptions *options, GString *str);
function M.addresses_iter(list)
	local i = -1
	return function()
		i = i + 1
		if i < galore.internet_address_list_length(list) then
			local ret = galore.internet_address_list_get_address(list, i)
			return i, ret
		end
	end
end

function M.show_addresses(list)
	local string = galore.internet_address_list_to_string(list, nil, false)
	if string == nil then
		return nil
	end
	return ffi.string(string)
end

function M.address_list_length(list)
	return galore.internet_address_list_length(list)
end

function M.address_list_append(list, append)
	galore.internet_address_list_append(list, append)
end

function M.address_list_remove(list, item)
	return galore.internet_address_list_remove(list, item)
end

function M.address_list_remove_at(list, idx)
	return galore.internet_address_list_remove_at(list, idx)
end

function M.message_get_subject(message)
	return ffi.string(galore.g_mime_message_get_subject(message))
end

function M.get_address_name(ia)
	return galore.internet_address_get_name(ia)
end

function M.internet_address_list(opt, str)
	local list = galore.internet_address_list_parse(opt, str)
	if list == nil then
		return nil
	end
	local i = 0
	return function()
		if i < galore.internet_address_list_length(list) then
			local addr = galore.internet_address_list_get_address(list, i)
			local mb = ffi.cast("InternetAddressMailbox *", addr)
			local email = ffi.string(galore.internet_address_mailbox_get_addr(mb))
			local name = ffi.string(galore.internet_address_get_name(addr))
			i = i + 1
			return name, email
		end
	end
end

--- XXX DONE
function M.new_part(cat, type)
	return galore.g_mime_part_new_with_type(cat, type)
end

--- XXX DONE
--- part_set_filename
function M.set_part_filename(attachment, name)
	galore.g_mime_part_set_filename(attachment, name)
end

function M.stream_open(file, mode, perm)
	local fd = assert(vim.loop.fs_open(file, mode, perm))
	return galore.g_mime_stream_fs_new(fd)
end

--- XXX DONE
function M.new_multipart(subtype)
	return galore.g_mime_multipart_new_with_subtype(subtype)
end

--- XXX DONE
function M.multipart_add(multi, part)
	return galore.g_mime_multipart_add(multi, ffi.cast("GMimeObject *", part))
end

--- XXX DONE
function M.message_set_mime(message, part)
	return galore.g_mime_message_set_mime_part(message, part)
end

--- XXX DONE
function M.message_set_subject(message, str, charset)
	return galore.g_mime_message_set_subject(message, str, charset)
end

function M.set_header(message, header, value)
	galore.g_mime_object_set_header(ffi.cast("GMimeObject *", message), header, value, nil)
end
function M.get_header(message, header)
	local ret = galore.g_mime_object_get_header(ffi.cast("GMimeObject *", message), header)
	if ret == nil then
		return nil
	end
	return ffi.string(ret)
end

--- XXX DONE
function M.new_text_part(type)
	return galore.g_mime_text_part_new_with_subtype(type)
end

function M.data_wrapper(stream, mode)
	if mode == "default" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_DEFAULT)
	elseif mode == "7bit" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_7BIT)
	elseif mode == "8bit" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_8BIT)
	elseif mode == "binary" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_BINARY)
	elseif mode == "base64" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_BASE64)
	elseif mode == "quotedprintable" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE)
	elseif mode == "uuencode" then
		return galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_UUENCODE)
	end
end

--- XXX DONE
function M.set_part_content(attachment, content)
	galore.g_mime_part_set_content(attachment, content)
end

-- GMimeFilter *g_mime_filter_basic_new (GMimeContentEncoding encoding, gboolean encode);
function M.filter_basic(enc, encode)
	return galore.g_mime_filter_basic_new(enc, false)
end

function M.wrapper_get_encoding(content)
	return galore.g_mime_data_wrapper_get_encoding(content)
end

--- XXX DONE
function M.set_encoding(part, mode)
	if mode == "default" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_DEFAULT)
	elseif mode == "7bit" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_7BIT)
	elseif mode == "8bit" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_8BIT)
	elseif mode == "binary" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_BINARY)
	elseif mode == "base64" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_BASE64)
	elseif mode == "quotedprintable" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE)
	elseif mode == "uuencode" then
		galore.g_mime_part_set_content_encoding(part, galore.GMIME_CONTENT_ENCODING_UUENCODE)
	end
end

-- XXX
function M.new_message(pretty)
	return galore.g_mime_message_new(pretty)
end

-- XXX
function M.set_charset(part, charset)
	galore.g_mime_text_part_set_charset(part, charset)
end

-- should we always set utf8 and QP?
-- XXX
function M.set_text(part, texts)
	local text = table.concat(texts, "\n")
	local charset = "utf-8"
	-- g_mime_charset_init (&mask);
	-- g_mime_charset_step (&mask, text, len);
	galore.g_mime_text_part_set_charset(part, charset)
	local stream = galore.g_mime_stream_mem_new_with_buffer(text, #text)
	local content = galore.g_mime_data_wrapper_new_with_stream(stream, galore.GMIME_CONTENT_ENCODING_DEFAULT)
	galore.g_mime_part_set_content(ffi.cast("GMimePart *", part), content)
	-- local encoding = galore.g_mime_part_get_content_encoding(ffi.cast("GMimePart *", part))
	galore.g_mime_part_set_content_encoding(
		ffi.cast("GMimePart *", part),
		galore.GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE
	)
	-- 	if (mask.level > 0)
	-- 		g_mime_part_set_content_encoding ((GMimePart *) mime_part, GMIME_CONTENT_ENCODING_8BIT);
	-- 	else
	-- 		g_mime_part_set_content_encoding ((GMimePart *) mime_part, GMIME_CONTENT_ENCODING_7BIT);
	-- maybe change charset later
end

function M.message_add_mailbox(message, type, name, addr)
	if type == "sender" then
		galore.g_mime_message_add_mailbox(message, galore.GMIME_ADDRESS_TYPE_SENDER, name, addr)
	elseif type == "from" then
		galore.g_mime_message_add_mailbox(message, galore.GMIME_ADDRESS_TYPE_FROM, name, addr)
	elseif type == "reply_to" then
		galore.g_mime_message_add_mailbox(message, galore.GMIME_ADDRESS_TYPE_REPLY_TO, name, addr)
	elseif type == "to" then
		galore.g_mime_message_add_mailbox(message, galore.GMIME_ADDRESS_TYPE_TO, name, addr)
	elseif type == "cc" then
		galore.g_mime_message_add_mailbox(message, galore.GMIME_ADDRESS_TYPE_CC, name, addr)
	elseif type == "bcc" then
		galore.g_mime_message_add_mailbox(message, galore.GMIME_ADDRESS_TYPE_BCC, name, addr)
	end
end

--- XXX DONE
function M.get_content(part)
	return galore.g_mime_part_get_content(ffi.cast("GMimePart *", part))
end

function M.get_stream(content)
	return galore.g_mime_data_wrapper_get_stream(content)
end

function M.new_filter_stream(stream)
	return galore.g_mime_stream_filter_new(stream)
end

-- returns a cstring, since we never use this as a string it's fine.
-- ffi.string seems to make it crash
function M.get_content_type_parameter(part, param)
	local obj = ffi.cast("GMimeObject *", part)
	return galore.g_mime_object_get_content_type_parameter(obj, param)
end

function M.filter_charset(from, to)
	local filter = galore.g_mime_filter_charset_new(from, to)
	-- ffi.gc(filter, galore.g_object_unref)
	return filter
end

function M.filter_dos2unix(newline)
	local filter = galore.g_mime_filter_dos2unix_new(newline)
	-- ffi.gc(filter, galore.g_object_unref)
	return filter
end

function M.filter_add(stream, filter)
	local filters = ffi.cast("GMimeStreamFilter *", stream)
	if filter ~= nil then
		galore.g_mime_stream_filter_add(filters, filter)
	end
	-- galore.g_object_unref(filter)
end

function M.new_mem_stream()
	local mem = galore.g_mime_stream_mem_new()
	galore.g_mime_stream_mem_set_owner(ffi.cast("GMimeStreamMem *", mem), false)
	-- ffi.gc(mem, galore.g_object_unref)
	return mem
end

function M.stream_to_stream(from, to)
	galore.g_mime_stream_write_to_stream(from, to)
end

-- function M.unref(obj)
-- 	galore.g_object_unref(obj)
-- end

function M.write_message(path, message)
	local err = ffi.new("GError *[1]")
	-- check error
	local stream = galore.g_mime_stream_file_open(path, "w+", err)
	galore.g_mime_object_write_to_stream(ffi.cast("GMimeObject *", message), nil, stream)
	galore.g_mime_stream_flush(stream)
	-- return error
end

function M.write_message_mem(message)
	local stream = M.new_mem_stream()
	galore.g_mime_object_write_to_stream(ffi.cast("GMimeObject *", message), nil, stream)
	galore.g_mime_stream_flush(stream)

	return M.mem_to_string(stream)
end

function M.mem_to_string(mem)
	galore.g_mime_stream_flush(mem)
	-- free this or does new_mem_stream free it?
	local array = galore.g_mime_stream_mem_get_byte_array(ffi.cast("GMimeStreamMem *", mem))
	return ffi.string(array.data, array.len)
end

function M.part_to_buf(part)
	local content = M.get_content(part)
	local stream = M.new_mem_stream()

	galore.g_mime_data_wrapper_write_to_stream(content, stream)
	-- do I need to do any formating on this.
	return M.mem_to_string(stream)
end

function M.save_part(part, filename)
	-- check if path is a directory, if so, use filename.
	-- if path is nil, just use filename
	-- if path is a file, don't use filename
	local fd = assert(vim.loop.fs_open(filename, "w", 438))
	local stream = galore.g_mime_stream_fs_new(fd)
	-- local stream = ffi.gc(galore.g_mime_stream_fs_new(fd), galore.g_object_unref)
	local content = M.get_content(part)

	galore.g_mime_data_wrapper_write_to_stream(content, stream)
	galore.g_mime_stream_flush(stream)
end

-- use this for testing only
function M._parse_message(path)
	local fd = galore.my_open(path)
	local stream = ffi.gc(galore.g_mime_stream_fs_new(fd), galore.g_object_unref)
	local parser = ffi.gc(galore.g_mime_parser_new_with_stream(stream), galore.g_object_unref)
	local message = ffi.gc(galore.g_mime_parser_construct_message(parser, nil), galore.g_object_unref)
	return message
end

function M.parse_message(path)
	local fd = assert(vim.loop.fs_open(path, "r", 438))
	-- local stream = ffi.gc(galore.g_mime_stream_fs_new(fd), galore.g_object_unref)
	-- local parser = ffi.gc(galore.g_mime_parser_new_with_stream(stream), galore.g_object_unref)
	-- local message = ffi.gc(galore.g_mime_parser_construct_message(parser, nil), galore.g_object_unref)
	local stream = galore.g_mime_stream_fs_new(fd)
	local parser = galore.g_mime_parser_new_with_stream(stream)
	local message = galore.g_mime_parser_construct_message(parser, nil)
	return message
	-- return galore.parse_message(filename)
end

function M.header_iter(message)
	-- local ls = galore.header_list(message)
	local ls = galore.g_mime_object_get_header_list(ffi.cast("GMimeObject *", message))
	if ls then
		local j = galore.g_mime_header_list_get_count(ls)
		local i = 0
		return function()
			if i < j then
				local header = galore.g_mime_header_list_get_header_at(ls, i)
				local key = ffi.string(galore.g_mime_header_get_name(header))
				local value = ffi.string(galore.g_mime_header_get_value(header))
				i = i + 1
				return key, value
			end
		end
	end
end

function M.remove_header(message, name)
	return galore.g_mime_object_remove_header(ffi.cast("GMimeObject *", message), name)
end

function M.get_message(part)
	local message = galore.g_mime_message_part_get_message(ffi.cast("GMimeMessagePart *", part))
	return message
end

function M.is_message_part(part)
	return galore.gmime_is_message_part(part) ~= 0
end

function M.is_partial(part)
	return galore.gmime_is_message_partial(part) ~= 0
end

function M.is_multipart(part)
	return galore.gmime_is_multipart(part) ~= 0
end

function M.is_part(part)
	return galore.gmime_is_part(part) ~= 0
end

function M.is_multipart_encrypted(part)
	return galore.gmime_is_multipart_encrypted(part) ~= 0
end

function M.is_multipart_signed(part)
	return galore.gmime_is_multipart_signed(part) ~= 0
end

function M.is_multipart_alt(part)
	local ct = M.get_content_type(part)
	local type = M.get_mime_type(ct)
	if type == "multipart/alternative" then
		return true
	end
	return false
end

--- XXX ERR?
function M.is_signed(part)
	return galore.g_mime_is_multipart_signed(part) ~= 0
end

function M.get_content_type(obj)
	return galore.g_mime_object_get_content_type(obj)
end

function M.get_mime_type(obj)
	return ffi.string(galore.g_mime_content_type_get_mime_type(obj))
end

-- XXX utils
function M.part_is_type(part, type, subtype)
	local content = galore.g_mime_object_get_content_type(part)
	return galore.g_mime_content_type_is_type(content, type, subtype)
end

-- XXX DONE
function M.part_filename(obj)
	local tmp = galore.g_mime_part_get_filename(obj)
	if tmp == nil then
		return nil
	end
	return ffi.string(tmp)
end

function M.reference_parse(options, str)
	return galore.g_mime_references_parse(options, str)
end

function M.references_append(ref, msgid)
	return galore.g_mime_references_append(ref, msgid)
end

function M.new_ref()
	return galore.g_mime_references_new()
end

-- dunno if this should actually free it
function M.reference_iterator(ref)
	local i = 0
	return function()
		if i < galore.g_mime_references_length(ref) then
			local ret = ffi.string(galore.g_mime_references_get_message_id(ref, i))
			i = i + 1
			return ret
		end
		galore.g_mime_references_clear(ref)
	end
end
-- I might want to have the neighbours also in the the same group
-- a bfs for multiparts
-- XXX DONE
function M.multipart_foreach(multipart, fun, state)
	local queue = {}
	local tmp = ffi.cast("GMimeObject *", multipart)
	table.insert(queue, { tmp, tmp })
	while #queue > 0 do
		local parent, part = unpack(table.remove(queue, 1))
		if parent ~= part then
			fun(parent, part, state)
		end
		if M.is_multipart(part) then
			local multi = ffi.cast("GMimeMultipart *", part)
			local i = 0
			local j = galore.multipart_len(multi)
			while i < j do
				local child = galore.multipart_child(multi, i)
				table.insert(queue, { part, child })
				i = i + 1
			end
		end
	end
end

-- XXX DONE
function M.multipart_foreach_dfs(part, parent, fun, state)
	if parent ~= part then
		fun(parent, part, state)
	end
	if M.is_multipart(part) then
		local multi = ffi.cast("GMimeMultipart *", part)
		local i = 0
		local j = galore.multipart_len(multi)
		while i < j do
			local child = galore.multipart_child(multi, i)
			M.multipart_foreach_dfs(child, part, fun, state)
			i = i + 1
		end
	end
end
-- XXX DONE
function M.message_foreach_dfs(message, fun, state)
	local part = galore.message_part(message)
	local obj = ffi.cast("GMimeObject *", message)
	fun(obj, part, state)

	if M.is_multipart(part) then
		M.multipart_foreach_dfs(part, part, fun, state)
	end
end

-- XXX DONE
-- function M.message_part(message)
-- 	return galore.message_part(message)
-- end

-- XXX DONE
function M.multipart_len(multi)
	return galore.multipart_len(multi)
end

-- XXX DONE
function M.multipart_child(multi, idx)
	return galore.multipart_child(multi, idx)
end

-- XXX DONE
function M.message_foreach(message, fun, state)
	local part = galore.message_part(message)
	local obj = ffi.cast("GMimeObject *", message)
	fun(obj, part, state)

	if M.is_multipart(part) then
		M.multipart_foreach(ffi.cast("GMimeMultipart*", part), fun, state)
	end
end

-- XXX DONE
function M.get_signed_part(part)
	-- local mps = ffi.cast("GMimeMultipartSigned *", part)
	return galore.g_mime_multipart_get_part(ffi.cast("GMimeMultipart *", part), galore.GMIME_MULTIPART_SIGNED_CONTENT)
end

local function sig_iterator(siglist)
	local i = galore.g_mime_signature_list_length(siglist)
	local j = 0
	return function()
		if j < i then
			local sig = galore.g_mime_signature_list_get_signature(siglist, j)
			j = j + 1
			return sig
		end
	end
end

local function verify(sig)
	-- XXX fix this, what should we accept?
	return galore.g_mime_signature_get_status(sig) == galore.GMIME_SIGNATURE_STATUS_GREEN
end

local function verify_list(siglist)
	if siglist == nil or galore.g_mime_signature_list_length(siglist) < 1 then
		return false
	end
	-- local ret = true

	for sig in sig_iterator(siglist) do
		if verify(sig) then
			return false
		end
	end
	return true
end

function M.new_gpg_contex()
	return galore.g_mime_gpg_context_new()
end

--- XXX DONE
-- @param recipients An array of recipient key ids and/or email addresses
function M.encrypt(ctx, part, id, recipients)
	-- convert a table to a C array
	-- we need to free this
	local gp_array = galore.g_ptr_array_sized_new(#recipients)
	for _, rep in pairs(recipients) do
		galore.g_ptr_array_add(gp_array, ffi.cast("gpointer", rep))
	end
	local error = ffi.new("GError*[1]")
	local obj = ffi.cast("GMimeObject *", part)
	local ret = galore.g_mime_multipart_encrypted_encrypt(
		ctx,
		obj,
		true,
		id,
		galore.GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS,
		gp_array,
		error
	)
	return ret, error
	-- return ret, ffi.string(galore.print_error(error[0]))
end

--- XXX DONE
function M.sign(ctx, part, id)
	local error = ffi.new("GError*[1]")
	local obj = ffi.cast("GMimeObject *", part)
	local ret = galore.g_mime_multipart_signed_sign(ctx, obj, id, error)
	return ret
	-- return ret, ffi.string(galore.print_error(error[0]))
end

--- XXX DONE
function M.verify_signed(part)
	local signed = ffi.cast("GMimeMultipartSigned *", part)
	local error = ffi.new("GError*[1]")
	local ret

	local signatures = galore.g_mime_multipart_signed_verify(
		signed,
		galore.GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS,
		error
	)
	if not signatures then
		-- XXX convert this into an error
		print("Failed to verify signed part: " .. error.message)
	else
		ret = verify_list(signatures)
	end
	return ret
end

function M.filter_reply(add)
	return galore.g_mime_filter_reply_new(add)
end

--- XXX DONE
function M.decrypt_and_verify(part)
	local encrypted = ffi.cast("GMimeMultipartEncrypted *", part)
	local error = ffi.new("GError*[1]")
	local res = ffi.new("GMimeDecryptResult*[1]")
	-- do we need to configure a session key?
	local session = nil
	local decrypted = galore.g_mime_multipart_encrypted_decrypt(
		encrypted,
		galore.GMIME_DECRYPT_ENABLE_KEYSERVER_LOOKUPS,
		session,
		res,
		error
	)

	local sign
	if res then
		sign = verify_list(galore.g_mime_decrypt_result_get_signatures(res[0]))
	end

	return decrypted, sign
end

function M.multipart_get_count(multipart)
	return galore.g_mime_multipart_get_count(multipart)
end
function M.multipart_get_part(multipart, index)
	return galore.g_mime_multipart_get_part(multipart, index)
end


return M
