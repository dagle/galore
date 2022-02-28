local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")
local M = {}

-- I might want to have the neighbours also in the the same group
-- a bfs for multiparts

--- @param multipart gmime.Multipart
--- @param fun fun(parent, part, state: table)
--- @param state table
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
			local j = gmime.g_mime_multipart_get_count(multi)
			while i < j do
				local child = gmime.g_mime_multipart_get_part(multi, i)
				table.insert(queue, { part, child })
				i = i + 1
			end
		end
	end
end

--- @param multipart gmime.Multipart
--- @param fun fun(parent, part, state: table)
--- @param state table
function M.multipart_foreach_dfs(multipart, parent, fun, state)
	if parent ~= multipart then
		fun(parent, multipart, state)
	end
	if M.is_multipart(multipart) then
		local multi = ffi.cast("GMimeMultipart *", multipart)
		local i = 0
		local j = gmime.g_mime_multipart_get_count(multi)
		while i < j do
			local child = gmime.g_mime_multipart_get_part(multi, i)
			M.multipart_foreach_dfs(child, multipart, fun, state)
			i = i + 1
		end
	end
end

--- @param message gmime.Message
--- @param fun fun(parent, part, state: table)
--- @param state table
--- A message walker that applies fun and does depth first search
function M.message_foreach_dfs(message, fun, state)
	if not message or not fun then
		return
	end
	local part = gmime.g_mime_message_get_mime_part(message)
	local obj = ffi.cast("GMimeObject *", message)
	fun(obj, part, state)

	if M.is_multipart(part) then
		M.multipart_foreach_dfs(part, part, fun, state)
	end
end

--- @param message gmime.Message
--- @param fun fun(parent, part, state: table)
--- @param state table
--- A message walker that applies fun and does breath first search
function M.message_foreach(message, fun, state)
	if not message or not fun then
		return
	end
	local part = gmime.g_mime_message_get_mime_part(message)
	local obj = ffi.cast("GMimeObject *", message)
	fun(obj, part, state)

	if M.is_multipart(part) then
		M.multipart_foreach(ffi.cast("GMimeMultipart*", part), fun, state)
	end
end

--- @param message gmime.Message
--- @return fun() current gmime.MimeObject, parent gmime.MimeObject
--- XXX untested
function M.part_iter(message)
	if message == nil then
		return
	end
	local tmp = gmime.g_mime_message_get_mime_part(message)
	local queue = {}
	table.insert(queue, { nil, tmp})
	return function()
		if #queue <= 0 then
			return nil
		end
		local parent, current = unpack(table.remove(queue, 1))
		if M.is_message_part(current) then
			local message_part = ffi.cast("GMimeMessagePart *", current)
			local new_message = gmime.g_mime_message_part_get_message(message_part)
			if new_message then
				local mime_part = gmime.g_mime_message_get_mime_part(new_message)
				-- XXX do we need to do this? Maybe because of ordering?
				-- table.insert(queue, { current, child })
				-- if M.is_multipart(mime_part) then
				-- 	local multi = ffi.cast("GMimeMultipart *", mime_part)
				-- 	local i = 0
				-- 	local j = gmime.g_mime_multipart_get_count(multi)
				-- 	while i < j do
				-- 		local child = gmime.g_mime_multipart_get_part(multi, i)
				-- 		table.insert(queue, { mime_part, child })
				-- 		i = i + 1
				-- 	end
				-- end
				table.insert(queue, { current, mime_part})
			end
		elseif M.is_multipart(current) then
			local multi = ffi.cast("GMimeMultipart *", current)
			local i = 0
			local j = gmime.g_mime_multipart_get_count(multi)
			while i < j do
				local child = gmime.g_mime_multipart_get_part(multi, i)
				table.insert(queue, { current, child })
				i = i + 1
			end
		end
		return current, parent
	end
end

--- @param pretty boolean
--- @return gmime.Message
function M.new_message(pretty)
	return ffi.gc(gmime.g_mime_message_new(pretty), gmime.g_object_unref)
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_from(message)
	return gmime.g_mime_message_get_from(message);
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_sender(message)
	return gmime.g_mime_message_get_sender(message);
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_reply_to(message)
	return gmime.g_mime_message_get_reply_to(message);
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_to(message)
	return gmime.g_mime_message_get_to(message);
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_cc(message)
	return gmime.g_mime_message_get_cc(message);
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_bcc(message)
	return gmime.g_mime_message_get_bcc(message);
end

--- @param message gmime.Message
--- @param type gmime.AddressType
--- @param name string
--- @param addr string
function M.message_add_mailbox(message, type, name, addr)
	-- local addrtype = convert.address_type(type)
	gmime.g_mime_message_add_mailbox(message, type, name, addr)
end

--- @param message gmime.Message
--- @param type gmime.AddressType
--- @return gmime.InternetAddressList
function M.message_get_address(message, type)
	-- local ctype = convert.address_type(type)
	local list = gmime.g_mime_message_get_addresses(message, type)
	return list
end

--- @param message gmime.Message
--- @return gmime.InternetAddressList
function M.message_get_all_recipients(message)
	return ffi.gc(gmime.g_mime_message_get_all_recipients(message), gmime.g_object_unref)
end

--- @param message gmime.Message
--- @param str string
--- @param charset string
function M.message_set_subject(message, str, charset)
	gmime.g_mime_message_set_subject(message, str, charset)
end

--- @param message gmime.Message
--- @return string
function M.message_get_subject(message)
	return ffi.string(gmime.g_mime_message_get_subject(message))
end

--- @param message gmime.Message
--- @param date number
function M.message_set_date(message, date)
	local gdate = gmime.g_date_time_new_from_unix_local(date)
	gmime.g_mime_message_set_date(message, gdate)
	gmime.g_date_time_unref(gdate)
end

--- @param message any
--- @return number
function M.message_get_date(message)
	local gdate = gmime.g_mime_message_get_date(message)
	local date = gmime.g_date_time_to_unix(gdate)
	gmime.g_date_time_unref(gdate)
	return tonumber(date)
end

--- @param message gmime.Message
--- @param message_id string
function M.message_set_message_id(message, message_id)
	gmime.g_mime_message_set_message_id(message, message_id)
end

--- @param message gmime.Message
--- @return string
function M.message_get_message_id(message)
	return ffi.string(gmime.g_mime_message_get_message_id(message))
end

--- @param message gmime.Message
--- @return gmime.MimeObject
function M.message_get_mime_part(message)
	return gmime.g_mime_message_get_mime_part(message)
end

--- @param message gmime.Message
--- @return gmime.MimeObject
function M.message_set_mime_part(message, part)
	return gmime.g_mime_message_set_mime_part(message, part)
end

--- @param message gmime.Message
--- @param now number
--- @return gmime.AutocryptHeader
function M.message_get_autocrypt_header(message, now)
	local gdate = gmime.g_date_time_new_from_unix_local(now)
	local ret = gmime.g_mime_message_get_autocrypt_header(message, gdate);
	gmime.g_date_time_unref(gdate)
	return ffi.gc(ret, gmime.g_object_unref)
end

--- @param message gmime.Message
--- @param now number
--- @param flags gmime.DecryptFlags
--- @param session_key string
--- @return gmime.AutocryptHeaderList, gmime.Error
function M.message_get_autocrypt_gossip_headers(message, now, flags, session_key)
	local err = ffi.new("GError*[1]")
	local gdate = gmime.g_date_time_new_from_unix_local(now)
	-- local eflags = convert.decrytion_flag(flags)
	local list = gmime.g_mime_message_get_autocrypt_gossip_headers(message, gdate, flags, session_key, err)
	gmime.g_date_time_unref(gdate)
	return ffi.gc(list, gmime.g_object_unref), err[0]
end

--- @param message gmime.Message
--- @param now number
--- @param inner_part gmime.MimeObject
--- @return gmime.AutocryptHeaderList
function M.message_get_autocrypt_gossip_headers_from_inner_part(message, now, inner_part)
	local gdate = gmime.g_date_time_new_from_unix_local(now)
	local ret = gmime.g_mime_message_get_autocrypt_gossip_headers_from_inner_part (message, gdate, inner_part)
	gmime.g_date_time_unref(gdate)
	return ffi.gc(ret, gmime.g_object_unref)
end

--- @param message gmime.Message
--- @return gmime.MimeObject
function M.message_get_body(message)
	return gmime.g_mime_message_get_body(message)
end

--- @return gmime.Part
function M.part_new()
	return ffi.gc(gmime.g_mime_part_new(), gmime.g_object_unref)
end

--- @param cat string
--- @param type string
--- @return gmime.Part
function M.new_part_with_type(cat, type)
	return ffi.gc(gmime.g_mime_part_new_with_type(cat, type), gmime.g_object_unref)
end

--- @param mime_part gmime.Part
--- @param description string
function M.part_set_content_description(mime_part, description)
	gmime.g_mime_part_set_content_description(mime_part, description)
end

--- @param mime_part gmime.Part
--- @return string
function M.part_get_content_description(mime_part)
	return ffi.string(gmime.g_mime_part_get_content_description(mime_part))
end

--- @param mime_part gmime.Part
--- @param content_id string
function M.part_set_content_id(mime_part, content_id)
	gmime.g_mime_part_set_content_id(mime_part, content_id)
end

--- @param mime_part gmime.Part
--- @return string
function M.part_get_content_id(mime_part)
	return ffi.string(gmime.g_mime_part_get_content_id(mime_part))
end

--- @param mime_part gmime.Part
--- @param content_md5 string
function M.part_set_content_md5(mime_part, content_md5)
	gmime.g_mime_part_set_content_md5(mime_part, content_md5)
end

--- @param mime_part gmime.Part
--- @return boolean
function M.part_verify_content_md5(mime_part)
	return gmime.g_mime_part_verify_content_md5(mime_part) ~= 0
end

--- @param mime_part gmime.Part
--- @return string
function M.part_get_content_md5(mime_part)
	return ffi.string(gmime.g_mime_part_get_content_md5(mime_part))
end

--- @param mime_part gmime.Part
--- @param content_location string
function M.part_set_content_location(mime_part, content_location)
	gmime.g_mime_part_set_content_location(mime_part, content_location)
end

--- @param mime_part gmime.Part
--- @return string
function M.part_get_content_location(mime_part)
	return ffi.string(gmime.g_mime_part_get_content_location(mime_part))
end

--- @param mime_part gmime.Part
--- @param mode string ("default"|"7bit"|"8bit"|"binary"|"base64"|"quotedprintable"|"uuencode")
function M.part_set_content_encoding(mime_part, mode)
	-- local gmode = convert.string_to_encoding(mode)
	gmime.g_mime_part_set_content_encoding(mime_part, mode)
end

--- @param mime_part gmime.Part
--- @return gmime.ContentEncoding
function M.part_get_content_encoding(mime_part)
	-- local gmode = gmime.g_mime_part_get_content_encoding(mime_part)
	-- return convert.encoding_to_string(gmode)
	return gmime.g_mime_part_get_content_encoding(mime_part)
end

--- @param mime_part gmime.Part
--- @param constraint gmime.ContentEncoding
--- @return gmime.ContentEncoding
function M.part_get_best_content_encoding(mime_part, constraint)
	local cconstraint = convert.to_encoding(constraint)
	-- local encoding = gmime.g_mime_part_get_best_content_encoding(mime_part, gmode)
	-- return convert.encoding_to_string(encoding)
	return gmime.g_mime_part_get_best_content_encoding(mime_part, cconstraint)
end

--- @param mime_part gmime.Part
--- @return boolean
function M.part_is_attachment(mime_part)
	return gmime.g_mime_part_is_attachment(mime_part) ~= 0
end

--- @param mime_part gmime.Part
--- @param filename string
function M.part_set_filename(mime_part, filename)
	gmime.g_mime_part_set_filename(filename)
end

--- @param mime_part gmime.Part
--- @return string
function M.part_get_filename(mime_part)
	return ffi.string(gmime.g_mime_part_get_filename(mime_part))
end

--- @param mime_part gmime.Part
--- @param content gmime.DataWrapper
function M.part_set_content(mime_part, content)
	gmime.g_mime_part_set_content(mime_part, content)
end

--- @param mime_part gmime.Part
--- @return gmime.DataWrapper
function M.part_get_content(mime_part)
	-- return gmime.g_mime_part_get_content(ffi.cast("GMimePart *", mime_part))
	return gmime.g_mime_part_get_content(mime_part)
end

--- @param mime_part gmime.Part
--- @param data gmime.OpenPGPData
function M.part_set_openpgp_data(mime_part, data)
	gmime.g_mime_part_set_openpgp_data(mime_part, data)
end

--- @param mime_part gmime.Part
--- @return gmime.OpenPGPData
function M.g_mime_part_get_openpgp_data(mime_part)
	return gmime.g_mime_part_get_openpgp_data(mime_part)
end

--- @param mime_part gmime.Part
--- @param sign boolean
--- @param userid string
--- @param flags gmime.EncryptFlags
--- @param recipients string[]
--- @return boolean, gmime.Error
function M.part_openpgp_encrypt(mime_part, sign, userid, flags, recipients)
	-- local eflags = convert.encryption_flags(flags)
	local array = gmime.g_ptr_array_sized_new(0)
	for _, rep in ipairs(recipients) do
		gmime.g_ptr_array_add(array, ffi.cast("gpointer", rep))
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_part_openpgp_encrypt(mime_part, sign, userid, flags, array, err) ~= 0
	gmime.g_ptr_array_unref(array)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

--- @param mime_part gmime.Part
--- @param flags string
--- @param session_key string
--- @return gmime.DecryptResult, gmime.Error
function M.part_openpgp_decrypt(mime_part, flags, session_key)
	local err = ffi.new("GError*[1]")
	local res = gmime.g_mime_part_openpgp_decrypt(mime_part, flags, session_key, err)
	return ffi.gc(res, gmime.g_object_unref), err[0]
end

--- @param mime_part gmime.Part
--- @param userid string
--- @return boolean, gmime.Error
function M.part_openpgp_sign(mime_part, userid)
	local err = ffi.new("GError*[1]")
	local res = gmime.g_mime_part_openpgp_sign(mime_part, userid, err) ~= 0
	return res ~= 0, err[0]
end

--- @param mime_part gmime.Part
--- @param flags string
--- @return gmime.SignatureList, gmime.Error
function M.g_mime_part_openpgp_verify(mime_part, flags)
	local err = ffi.new("GError*[1]")
	local res = gmime.g_mime_part_openpgp_verify(mime_part, flags, err)
	return ffi.gc(res, gmime.g_object_unref), err[0]
end

--- @param subtype string
--- @return gmime.Messagepart
function M.message_part_new(subtype)
	return ffi.gc(gmime.g_mime_message_part_new(subtype), gmime.g_object_unref)
end

--- @param subtype string
--- @param message gmime.Message
--- @return gmime.Messagepart
function M.message_part_new_with_message(subtype, message)
	return ffi.gc(gmime.g_mime_message_part_new_with_message(subtype, message), gmime.g_object_unref)
end

--- @param part gmime.Messagepart
--- @param message gmime.Message
function M.message_part_set_message(part, message)
	gmime.g_mime_message_part_set_message(part, message)
end

--- @param part gmime.Messagepart
--- @return gmime.Message
function M.message_part_get_message(part)
	return gmime.g_mime_message_part_get_message(part)
end

--- @param id string
--- @param number number
--- @param total number
--- @return gmime.Messagepartial
function M.message_partial_new(id, number, total)
	return ffi.gc(gmime.g_mime_message_partial_new(id, number, total), gmime.g_object_unref)
end

--- @param partial gmime.Messagepartial
--- @return string
function M.message_partial_get_id(partial)
	return ffi.string(gmime.g_mime_message_partial_get_id(partial))
end

--- @param partial gmime.Messagepartial
--- @return number
function M.message_partial_get_number(partial)
	return gmime.g_mime_message_partial_get_number(partial)
end

--- @param partial gmime.Messagepartial
--- @return number
function M.message_partial_get_total(partial)
	return gmime.g_mime_message_partial_get_total(partial)
end

--- @param partials gmime.Messagepartial[]
--- @param num number
--- @return gmime.Message
function M.message_partial_reconstruct_message(partials, num)
	local array = ffi.new("GMimeMessagePartial[?]", num)
	for i = 0, num do
		array[i] = partials[i+1]
	end
	return ffi.gc(gmime.g_mime_message_partial_reconstruct_message(array, num), gmime.g_object_unref)
end

--- @param message gmime.Message
--- @param max_size number
--- @return gmime.Message[]
--- XXX
function M.message_partial_split_message(message, max_size)
	local nparts = ffi.new("size_t[1]")
	local array =  gmime.g_mime_message_partial_split_message(message, max_size, nparts)
	--- Can we free array without copying all the massages?
	-- local num = tonumber(nparts[0])
	-- local ret = {}
	-- for i = 0, num do
	-- 	table.insert(ret, array[i])
	-- end
	-- return ret
	return array
end

--- @return gmime.Multipart
function M.multipart_new()
	return ffi.gc(gmime.g_mime_multipart_new(), gmime.g_object_unref)
end

--- @param subtype string
--- @return gmime.Multipart
function M.multipart_new_with_subtype(subtype)
	return ffi.gc(gmime.g_mime_multipart_new_with_subtype(subtype), gmime.g_object_unref)
end

--- @param multipart gmime.Multipart
--- @param prologue string
function M.multipart_set_prologue(multipart, prologue)
	gmime.g_mime_multipart_set_prologue(multipart, prologue)
end

--- @param multipart gmime.Multipart
--- @return string
function M.multipart_get_prologue(multipart)
	return ffi.string(gmime.g_mime_multipart_get_prologue(multipart))
end

--- @param multipart gmime.Multipart
--- @param epilogue string
function M.multipart_set_epilogue(multipart, epilogue)
	gmime.g_mime_multipart_set_epilogue(multipart, epilogue)
end

--- @param multipart gmime.Multipart
--- @return string
function M.multipart_get_epilogue(multipart)
	return ffi.string(gmime.g_mime_multipart_get_epilogue(multipart))
end

-- @param multipart gmime.Multipart
function M.multipart_clear(multipart)
	gmime.g_mime_multipart_clear(multipart)
end

--- @param multipart gmime.Multipart
--- @param part gmime.MimeObject
function M.multipart_add(multipart, part)
	-- gmime.g_mime_multipart_add(multi, ffi.cast("GMimeObject *", part))
	gmime.g_mime_multipart_add(multipart, part)
end

--- @param multipart gmime.Multipart
--- @param index number
--- @param part gmime.MimeObject
function M.multipart_insert(multipart, index, part)
	gmime.g_mime_multipart_insert(multipart, index, part)
end

--- @param multipart gmime.Multipart
--- @param part gmime.MimeObject
--- @return boolean
function M.multipart_remove(multipart, part)
	return gmime.g_mime_multipart_remove(multipart, part) ~= 0
end

--- @param multipart gmime.Multipart
--- @param index number
--- @return gmime.MimeObject
function M.multipart_remove_at(multipart, index)
	return gmime.g_mime_multipart_remove_at(multipart, index)
end

--- @param multipart gmime.Multipart
--- @param index number
--- @param replacment gmime.MimeObject
--- @return gmime.MimeObject
function M.multipart_replace(multipart, index, replacment)
	return ffi.gc(gmime.g_mime_multipart_replace(multipart, index, replacment), gmime.g_object_unref)
end

--- @param multipart gmime.Multipart
--- @param index number
--- @return gmime.MimeObject
function M.multipart_get_part(multipart, index)
	return gmime.g_mime_multipart_get_part(multipart, index)
end

--- @param multipart gmime.Multipart
--- @param part gmime.MimeObject
--- @return boolean
function M.multipart_contains(multipart, part)
	return gmime.g_mime_multipart_contains(multipart, part) ~= 0
end

--- @param multipart gmime.Multipart
--- @param part gmime.MimeObject
--- @return number
function M.multipart_index_of(multipart, part)
	return gmime.g_mime_multipart_index_of(multipart, part)
end

--- @param multipart gmime.Multipart
--- @return number
function M.multipart_get_count(multipart)
	return gmime.g_mime_multipart_get_count(multipart)
end

--- @param multipart gmime.Multipart
--- @param boundary string
function M.multipart_set_boundary(multipart, boundary)
	gmime.g_mime_multipart_set_boundary(multipart, boundary)
end

--- @param multipart gmime.Multipart
--- @return string
function M.multipart_get_boundary(multipart)
	return ffi.string(gmime.g_mime_multipart_get_boundary(multipart))
end

--- @param multipart gmime.Multipart
--- @param content_id string
function M.multipart_get_subpart_from_content_id(multipart, content_id)
	gmime.g_mime_multipart_get_subpart_from_content_id(multipart, content_id)
end

--- @return gmime.MultipartSigned
function M.multipart_signed_new()
	return ffi.gc(gmime.g_mime_multipart_signed_new(), gmime.g_object_unref)
end

--- @param ctx gmime.CryptoContext
--- @param entity gmime.MimeObject
--- @param userid string
--- @return gmime.MultipartSigned, gmime.Error
function M.multipart_signed_sign(ctx, entity, userid)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_multipart_signed_sign(ctx, entity, userid, err)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

local function string_toverify(flag)
	if flag == "none" then
		return gmime.GMIME_VERIFY_NONE
	elseif flag == "keyserver" then
		return gmime.GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS
	elseif flag == "online" then
		return gmime.GMIME_VERIFY_ENABLE_ONLINE_CERTIFICATE_CHECKS
	end
end

--- @param mps gmime.MultipartSigned
--- @param flags string
--- @return gmime.SignatureList, gmime.Error
function M.multipart_signed_verify(mps, flags)
	local err = ffi.new("GError*[1]")
	local eflags = string_toverify(flags)
	local ret = gmime.g_mime_multipart_signed_verify(mps, eflags, err)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

--- @return gmime.MultipartEncrypted
function M.multipart_encrypted_new()
	return ffi.gc(gmime.g_mime_multipart_encrypted_new(), gmime.g_object_unref)
end

--- @param ctx gmime.CryptoContext
--- @param entity gmime.MimeObject
--- @param sign boolean
--- @param userid string
--- @param flags gmime.EncryptFlags
--- @param recipients string[]
--- @return gmime.MultipartEncrypted, gmime.Error
function M.multipart_encrypted_encrypt(ctx, entity, sign, userid, flags, recipients)
	local err = ffi.new("GError*[1]")
	-- local eflags = convert.encryption_flags(flags)
	local array = gmime.g_ptr_array_sized_new(0)
	for _, rep in pairs(recipients) do
		gmime.g_ptr_array_add(array, ffi.cast("gpointer", rep))
	end
	local multi = gmime.g_mime_multipart_encrypted_encrypt(ctx, entity, sign, userid, flags, array, err)
	gmime.g_ptr_array_unref(array, false)
	return ffi.gc(multi, gmime.g_object_unref), err[0]
end

--- Should take a table or a string of values and then do bit ops
--- @param part gmime.MultipartEncrypted
--- @param flags gmime.DecryptFlags
--- @param session_key string
--- @return gmime.MimeObject, gmime.DecryptResult, gmime.Error
function M.multipart_encrypted_decrypt(part, flags, session_key)
	local err = ffi.new("GError*[1]")
	local res = ffi.new("GMimeDecryptResult*[1]")
	-- local eflags = convert.decrytion_flag(flags)
	local obj = gmime.g_mime_multipart_encrypted_decrypt(part, flags, session_key, res, error)
	return ffi.gc(obj, gmime.g_object_unref), res[0], err[0]
end

--- @return gmime.TextPart
function M.text_part_new()
	return ffi.gc(gmime.g_mime_text_part_new(), gmime.g_object_unref)
end

--- @param subtype string
--- @return gmime.TextPart
function M.text_part_new_with_subtype(subtype)
	return ffi.gc(gmime.g_mime_text_part_new_with_subtype(subtype), gmime.g_object_unref)
end

--- @param mime_part gmime.TextPart
--- @param charset string
function M.text_part_set_charset(mime_part, charset)
	gmime.g_mime_text_part_set_charset(mime_part, charset)
end

--- @param mime_part gmime.TextPart
--- @return string
function M.text_part_get_charset(mime_part)
	return ffi.string(gmime.g_mime_text_part_get_charset(mime_part))
end

--- @param mime_part gmime.TextPart
--- @param text string
function M.text_part_set_text(mime_part, text)
	gmime.g_mime_text_part_set_text(mime_part, text)
end

--- @param mime_part gmime.TextPart
--- @return string
function M.text_part_get_text(mime_part)
	return ffi.string(gmime.g_mime_text_part_get_text(mime_part))
end

-- macros
--- @param part gmime.MimeObject
--- @return boolean
function M.is_message_part(part)
	return gmime.gmime_is_message_part(part) ~= 0
end

--- @param part gmime.MimeObject
--- @return boolean
function M.is_partial(part)
	return gmime.gmime_is_message_partial(part) ~= 0
end

--- @param part gmime.MimeObject
--- @return boolean
function M.is_multipart(part)
	return gmime.gmime_is_multipart(part) ~= 0
end

--- @param part gmime.MimeObject
--- @return boolean
function M.is_part(part)
	return gmime.gmime_is_part(part) ~= 0
end

--- @param part gmime.MimeObject
--- @return boolean
function M.is_multipart_encrypted(part)
	return gmime.gmime_is_multipart_encrypted(part) ~= 0
end

--- @param part gmime.MimeObject
--- @return boolean
function M.is_multipart_signed(part)
	return gmime.gmime_is_multipart_signed(part) ~= 0
end

-- function M.set_text(part, texts)
-- 	local text = table.concat(texts, "\n")
-- 	local charset = "utf-8"
	-- g_mime_charset_init (&mask);
	-- g_mime_charset_step (&mask, text, len);
	-- gmime.g_mime_text_part_set_charset(part, charset)
	-- local stream = gmime.g_mime_stream_mem_new_with_buffer(text, #text)
	-- local content = gmime.g_mime_data_wrapper_new_with_stream(stream, gmime.GMIME_CONTENT_ENCODING_DEFAULT)
	-- gmime.g_mime_part_set_content(ffi.cast("GMimePart *", part), content)
	-- -- local encoding = galore.g_mime_part_get_content_encoding(ffi.cast("GMimePart *", part))
	-- gmime.g_mime_part_set_content_encoding(
	-- 	ffi.cast("GMimePart *", part),
	-- 	gmime.GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE
	-- )
	-- 	if (mask.level > 0)
	-- 		g_mime_part_set_content_encoding ((GMimePart *) mime_part, GMIME_CONTENT_ENCODING_8BIT);
	-- 	else
	-- 		g_mime_part_set_content_encoding ((GMimePart *) mime_part, GMIME_CONTENT_ENCODING_7BIT);
	-- maybe change charset later
-- end

return M
