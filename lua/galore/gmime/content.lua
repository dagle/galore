--- @diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local safe = require("galore.gmime.funcs")
local ffi = require("ffi")

local M = {}

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_content_disposition(header, options, value, charset)
	local mem = gmime.g_mime_header_format_content_disposition(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_content_type(header, options, value, charset)
	local mem = gmime.g_mime_header_format_content_type(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_message_id(header, options, value, charset)
	local mem = gmime.g_mime_header_format_message_id(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_references(header, options, value, charset)
	local mem = gmime.g_mime_header_format_references(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_addrlist(header, options, value, charset)
	local mem = gmime.g_mime_header_format_addrlist(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_received(header, options, value, charset)
	local mem = gmime.g_mime_header_format_received(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_default(header, options, value, charset)
	local mem = gmime.g_mime_header_format_default(header, options, value, charset)
	return safe.strdup(mem)
end

--- @param header gmime.Header
--- @return string
function M.header_get_name(header)
	return safe.safestring(gmime.g_mime_header_get_name(header))
end

--- @param header gmime.Header
--- @return string
function M.header_get_raw_name(header)
	return ffi.string(gmime.g_mime_header_get_raw_name(header))
end

--- @param header gmime.Header
--- @return string
function M.header_get_value(header)
	return safe.safestring(gmime.g_mime_header_get_value(header))
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_set_value(header, options, value, charset)
	gmime.g_mime_header_set_value(header, options, value, charset)
end

--- @param header gmime.Header
--- @return string
function M.header_get_raw_value(header)
	return ffi.string(gmime.g_mime_header_get_raw_value(header))
end

--- @param header gmime.Header
--- @param raw_value string
function M.header_set_raw_value(header, raw_value)
	gmime.g_mime_header_set_raw_value(header, raw_value)
end

--- @param header gmime.Header
--- @return number
function M.header_get_offset(header)
	return tonumber(gmime.g_mime_header_get_offset(header))
end

--- @param header gmime.Header
--- @param options gmime.Option
--- @param stream gmime.Stream
--- @return number
function M.header_write_to_stream(header, options, stream)
	return gmime.g_mime_header_write_to_stream(header, options, stream)
end

--- @param options gmime.Option
--- @return gmime.HeaderList
function M.header_list_new(options)
	return ffi.gc(gmime.g_mime_header_list_new(options), gmime.g_object_unref)
end

--- @param headers gmime.HeaderList
function M.header_list_clear(headers)
	gmime.g_mime_header_list_clear(headers)
end

--- @param headers gmime.HeaderList
--- @return number
function M.header_list_get_count(headers)
	return gmime.g_mime_header_list_get_count(headers)
end

--- @param headers gmime.HeaderList
--- @param name string
--- @return boolean
function M.header_list_contains(headers, name)
	return gmime.g_mime_header_list_contains(headers, name) ~= 0
end

--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_list_prepend(headers, options, value, charset)
	gmime.g_mime_header_list_prepend(headers, options, value, charset)
end

--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_list_append(headers, options, value, charset)
	gmime.g_mime_header_list_append(headers, options, value, charset)
end

--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_list_set(headers, options, value, charset)
	gmime.g_mime_header_list_set(headers, options, value, charset)
end

--- @param headers gmime.HeaderList
--- @param name string
--- @return gmime.Header
function M.header_list_get_header(headers, name)
	return gmime.g_mime_header_list_get_header(headers, name)
end

--- @param headers gmime.HeaderList
--- @param index number
--- @return gmime.Header
function M.header_list_get_header_at(headers, index)
	return gmime.g_mime_header_list_get_header_at(headers, index)
end

--- @param headers gmime.HeaderList
--- @param index number
--- @return boolean
function M.header_list_remove(headers, index)
	return gmime.g_mime_header_list_remove(headers, index) ~= 0
end

--- @param headers gmime.HeaderList
--- @param index number
function M.header_list_remove_at(headers, index)
	gmime.g_mime_header_list_remove_at(headers, index)
end

--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param stream gmime.Stream
--- @return number
function M.header_list_write_to_stream(headers, options, stream)
	return tonumber(gmime.g_mime_header_list_write_to_stream(headers, options, stream))
end

--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @return string
function M.header_list_to_string(headers, options)
	local mem = gmime.g_mime_header_list_to_string(headers, options)
	return safe.strdup(mem)
end

--- @param str string
--- @return integer
function M.utils_header_decode_date(str)
	local gdate = gmime.g_mime_utils_header_decode_date(str)
	local date = gmime.g_date_time_to_unix(gdate)
	gmime.g_date_time_unref(gdate)
	return date
end

--- @param date integer
--- @return string
function M.utils_header_format_date(date)
	local gdate = gmime.g_date_time_new_from_unix_local(date)
	local str = ffi.string(gmime.g_mime_utils_header_format_date(gdate))
	gmime.g_date_time_unref(gdate)
	return str
end

--- @param fqdn string
--- @return string
function M.utils_generate_message_id(fqdn)
	local mem = gmime.g_mime_utils_generate_message_id(fqdn)
	return safe.strdup(mem)
end

--- @param message_id string
--- @return string
function M.utils_decode_message_id(message_id)
	local mem = gmime.g_mime_utils_decode_message_id(message_id)
	return safe.strdup(mem)
end

--- @param options gmime.Option
--- @param format gmime.FormatOptions
--- @param header string
--- @return string
function M.utils_structured_header_fold(options, format, header)
	local mem = gmime.g_mime_utils_structured_header_fold(options, format, header)
	return safe.strdup(mem)
end

--- @param options gmime.Option
--- @param format gmime.FormatOptions
--- @param header string
--- @return string
function M.utils_unstructured_header_fold(options, format, header)
	local mem = gmime.g_mime_utils_unstructured_header_fold(options, format, header)
	return safe.strdup(mem)
end

--- @param option gmime.Option
--- @param format gmime.Format
--- @param text string
--- @param ... any
--- @return string
function M.utils_header_printf(option, format, text, ...)
	local mem = gmime.g_mime_utils_header_printf(option, format, text, ...)
	return safe.strdup(mem)
end

--- @param value string
--- @return string
function M.utils_header_unfold(value)
	local mem = gmime.g_mime_utils_header_unfold(value)
	return safe.strdup(mem)
end

--- @param str string
--- @return string
function M.utils_quote_string(str)
	local mem = gmime.g_mime_utils_quote_string(str)
	return safe.strdup(mem)
end

--- @param str string
--- @return string
function M.utils_unquote_string(str)
	local mem = gmime.utils_unquote_string(str)
	return safe.strdup(mem)
end

--- @param text string
--- @return boolean
--- XXX Is it ok for this 3 functions to work on 8bit text only?
function M.utils_text_is_8bit(text)
	return gmime.g_mime_utils_text_is_8bit(text, #text) ~= 0
end

--- @param text string
--- @return gmime.ContentEncoding
function M.utils_best_encoding(text)
	return gmime.g_mime_utils_best_encoding(text, #text)
end

--- @param options gmime.Option
--- @param text string
--- @return string
function M.utils_decode_8bit(options, text)
	local mem = gmime.g_mime_utils_decode_8bit(options, text, #text)
	return safe.strdup(mem)
end

--- @param options gmime.Option
--- @param text string
--- @return string
function M.utils_header_decode_text(options, text)
	local mem = gmime.g_mime_utils_header_decode_text(options, text)
	return safe.strdup(mem)
end

--- @param options gmime.Option
--- @param text string
--- @param charset string
--- @return string
function M.utils_header_encode_text(options, text, charset)
	local mem = gmime.g_mime_utils_header_encode_text(options, text, charset)
	return safe.strdup(mem)
end

--- @param options gmime.Option
--- @param phrase string
--- @return string
function M.utils_header_decode_phrase(options, phrase)
	local mem = gmime.g_mime_utils_header_decode_phrase(options, phrase)
	return safe.strdup(mem)
end

--- @param options gmime.Option
--- @param phrase string
--- @param charset string
--- @return string
function M.utils_header_encode_phrase(options, phrase, charset)
	local mem = gmime.g_mime_utils_header_encode_phrase(options, phrase, charset)
	return safe.strdup(mem)
end

--- @param ia gmime.InternetAddress
--- @param name string
function M.internet_address_set_name(ia, name)
	gmime.internet_address_set_name(ia, name)
end

--- @param ia gmime.InternetAddress
--- @return string
function M.internet_address_get_name(ia)
	return safe.safestring(gmime.internet_address_get_name(ia))
end

--- @param ia gmime.InternetAddress
--- @param charset string
function M.internet_address_set_charset(ia, charset)
	gmime.internet_address_set_charset(ia, charset)
end

--- @param ia gmime.InternetAddress
--- @return string
function M.internet_address_get_charset(ia)
	return ffi.string(gmime.internet_address_get_charset(ia))
end

--- @param ia gmime.InternetAddress
--- @param option gmime.FormatOptions
--- @param encode boolean
--- @return string
function M.internet_address_to_string(ia, option, encode)
	local mem = gmime.internet_address_to_string(ia, option, encode)
	return safe.strdup(mem)
end

--- @param name string
--- @param addr string
--- @return gmime.InternetAddress
function M.internet_address_mailbox_new(name, addr)
	return ffi.gc(gmime.internet_address_mailbox_new(name, addr), gmime.g_object_unref)
end

--- @param mb gmime.InternetAddressMailbox
--- @param addr string
function M.internet_address_mailbox_set_addr(mb, addr)
	gmime.internet_address_mailbox_set_addr(mb, addr)
end

--- @param mb gmime.InternetAddressMailbox
--- @return string
function M.internet_address_mailbox_get_addr(mb)
	return safe.safestring(gmime.internet_address_mailbox_get_addr(mb))
end

--- @param mb gmime.InternetAddressMailbox
--- @return string
function M.internet_address_mailbox_get_idn_addr(mb)
	return safe.safestring(gmime.internet_address_mailbox_get_idn_addr(mb))
end

--- @param name string
--- @return gmime.InternetAddress
function M.internet_address_group_new(name)
	return ffi.gc(gmime.internet_address_group_new(name), gmime.g_object_unref)
end

--- @param group gmime.InternetAddressGroup
--- @param members gmime.InternetAddressList
function M.internet_address_group_set_members(group, members)
	gmime.internet_address_group_set_members(group, members)
end

--- @param group gmime.InternetAddressGroup
--- @return gmime.InternetAddressList
function M.internet_address_group_get_members(group)
	return gmime.internet_address_group_get_members(group)
end

--- @param group gmime.InternetAddressGroup
--- @param member gmime.InternetAddress
--- @return number
function M.internet_address_group_add_member(group, member)
	return gmime.internet_address_group_add_member(group, member)
end

--- @return gmime.InternetAddressList
function M.internet_address_list_new()
	return ffi.gc(gmime.internet_address_list_new(), gmime.g_object_unref)
end

--- @param list gmime.InternetAddressList
--- @return number
function M.internet_address_list_length(list)
	return gmime.internet_address_list_length(list)
end

--- @param list gmime.InternetAddressList
function M.internet_address_list_clear(list)
	gmime.internet_address_list_clear(list)
end

--- @param list gmime.InternetAddressList
--- @param ia gmime.InternetAddress
--- @return number
function M.internet_address_list_add(list, ia)
	return gmime.internet_address_list_add(list, ia)
end

--- @param list gmime.InternetAddressList
--- @param prepend gmime.InternetAddressList
function M.internet_address_list_prepend(list, prepend)
	gmime.internet_address_list_prepend(list, prepend)
end

--- @param list gmime.InternetAddressList
--- @param append gmime.InternetAddressList
function M.internet_address_list_append(list, append)
	gmime.internet_address_list_append(list, append)
end

--- @param list gmime.InternetAddressList
--- @param index number
--- @param ia gmime.InternetAddress
function M.internet_address_list_insert(list, index, ia)
	gmime.internet_address_list_insert(list, index, ia)
end

--- @param list gmime.InternetAddressList
--- @param ia gmime.InternetAddress
--- @return boolean
function M.internet_address_list_remove(list, ia)
	return gmime.internet_address_list_remove(list, ia) ~= 0
end

--- @param list gmime.InternetAddressList
--- @param index number
--- @return boolean
function M.internet_address_list_remove_at(list, index)
	return gmime.internet_address_list_remove_at(list, index) ~= 0
end

--- @param list gmime.InternetAddressList
--- @param ia gmime.InternetAddress
--- @return boolean
function M.internet_address_list_contains(list, ia)
	return gmime.internet_address_list_contains(list, ia) ~= 0
end

--- @param list gmime.InternetAddressList
--- @param ia list gmime.InternetAddress
--- @return boolean
function M.internet_address_list_index_of(list, ia)
	return gmime.internet_address_list_index_of(list, ia) ~= 0
end

--- @param list gmime.InternetAddressList
--- @param index number
--- @return gmime.InternetAddress
function M.internet_address_list_get_address(list, index)
	return gmime.internet_address_list_get_address(list, index)
end

--- @param list gmime.InternetAddressList
--- @param index number
--- @param ia list gmime.InternetAddress
function M.internet_address_list_set_address(list, index, ia)
	return gmime.internet_address_list_set_address(list, index, ia)
end

--- @param options gmime.FormatOptions
--- @param encode boolean
--- @return string
function M.internet_address_list_to_string(list, options, encode)
	return safe.safestring(gmime.internet_address_list_to_string(list, options, encode))
end

--- @param list gmime.InternetAddressList
--- @param options gmime.FormatOptions
function M.internet_address_list_encode(list, options, str)
	gmime.internet_address_list_encode(list, options, str)
end

--- @param options gmime.ParserOptions
--- @param str string
--- @return gmime.InternetAddressList
function M.internet_address_list_parse(options, str)
	return gmime.internet_address_list_parse(options, str)
end

---@param ia gmime.InternetAddress
---@return boolean
function M.internet_address_is_mailbox(ia)
	return gmime.internet_address_is_mailbox(ia) ~= 0
end

---@param ia gmime.InternetAddress
---@return boolean
function M.internet_address_is_group(ia)
	return gmime.internet_address_is_group(ia) ~= 0
end

--- @retun gmime.ContentDisposition
function M.content_disposition_new()
	return ffi.gc(gmime.g_mime_content_disposition_new(), gmime.g_object_unref)
end

--- @param options gmime.Option
--- @param str string
--- @retun gmime.ContentDisposition
function M.content_disposition_parse(options, str)
	return gmime.g_mime_content_disposition_parse(options, str)
end

--- @param value string
function M.content_disposition_set_disposition(disposition, value)
	gmime.g_mime_content_disposition_parse(disposition, value)
end

--- @param disposition gmime.ContentDisposition
--- @return string
function M.content_disposition_get_disposition(disposition)
	ffi.string(gmime.g_mime_content_disposition_get_disposition(disposition))
end

--- @param disposition gmime.ContentDisposition
--- @return gmime.ParamList
function M.content_disposition_get_parameters(disposition)
	return gmime.g_mime_content_disposition_get_parameters(disposition)
end

--- @param disposition gmime.ContentDisposition
--- @param name string
--- @param value string
function M.content_disposition_set_parameter(disposition, name, value)
	gmime.g_mime_content_disposition_set_parameter(disposition, name, value)
end

--- @param disposition gmime.ContentDisposition
--- @param name string
function M.content_disposition_get_parameter(disposition, name)
	return ffi.string(gmime.g_mime_content_disposition_get_parameter(disposition, name))
end

--- @param disposition gmime.ContentDisposition
function M.content_disposition_is_attachment(disposition)
	return gmime.g_mime_content_disposition_is_attachment(disposition)
end

--- @param disposition gmime.ContentDisposition
--- @param options gmime.FormatOptions
function M.content_disposition_encode(disposition, options)
	return ffi.string(gmime.g_mime_content_disposition_encode(disposition, options))
end

--- @param type string
--- @param subtype string
--- @return gmime.ContentType
function M.content_type_new(type, subtype)
	return ffi.gc(gmime.g_mime_content_type_new(type, subtype), gmime.g_object_unref)
end

--- @param options gmime.ParserOptions
--- @param str string
--- @return gmime.ContentType
function M.content_type_parse(options, str)
	return gmime.g_mime_content_type_parse(options, str)
end

--- @param content_type gmime.ContentType
--- @return string
function M.content_type_get_mime_type(content_type)
	return ffi.string(gmime.g_mime_content_type_get_mime_type(content_type))
end

--- @param content_type gmime.ContentType
--- @param options gmime.FormatOptions
--- @return string
function M.content_type_encode(content_type, options)
	return ffi.string(gmime.g_mime_content_type_encode(content_type, options))
end

--- @param content_type gmime.ContentType
--- @param type string
--- @param subtype string
function M.content_type_is_type(content_type, type, subtype)
	return gmime.g_mime_content_type_is_type(content_type, type, subtype) ~= 0
end

--- @param content_type gmime.ContentType
--- @param type string
function M.content_type_set_media_type(content_type, type)
	gmime.g_mime_content_type_set_media_type(content_type, type)
end

--- @param content_type gmime.ContentType
--- @return string
function M.content_type_get_media_type(content_type)
	return ffi.string(gmime.g_mime_content_type_get_media_type(content_type))
end

--- @param content_type gmime.ContentType
--- @param subtype string
function M.content_type_set_media_subtype(content_type, subtype)
	gmime.g_mime_content_type_set_media_subtype(content_type, subtype)
end

--- @param content_type gmime.ContentType
--- @return string
function M.content_type_get_media_subtype(content_type)
	return ffi.string(gmime.g_mime_content_type_get_media_subtype(content_type))
end

--- @param content_type gmime.ContentType
--- @return gmime.ParamList
function M.content_type_get_parameters(content_type)
	return gmime.g_mime_content_type_get_parameters(content_type)
end

--- @param content_type gmime.ContentType
--- @param name string
--- @param value string
function M.content_type_set_parameter(content_type, name, value)
	gmime.g_mime_content_type_set_parameter(content_type, name, value)
end

--- @param content_type gmime.ContentType
--- @param name string
--- @return string
function M.content_type_get_parameter(content_type, name)
	return ffi.string(gmime.g_mime_content_type_get_parameter(content_type, name))
end

--- @return gmime.References
function M.references_new()
	return ffi.gc(gmime.g_mime_references_new(), M.references_free)
end

--- @param refs gmime.References
function M.references_free(refs)
	gmime.g_mime_references_free(refs)
end

--- @param options gmime.ParserOptions
--- @param text string
--- @return gmime.References
function M.references_parse(options, text)
	return ffi.gc(gmime.g_mime_references_parse(options, text), M.references_free)
end

--- @param refs gmime.References
function M.references_copy(refs)
	return gmime.g_mime_references_copy(refs)
end

--- @param refs gmime.References
function M.references_length(refs)
	return gmime.g_mime_references_length(refs)
end

--- @param refs gmime.References
--- @param msgid string
function M.references_append(refs, msgid)
	gmime.g_mime_references_append(refs, msgid)
end

--- @param refs gmime.References
function M.references_clear(refs)
	gmime.g_mime_references_clear(refs)
end

--- @param refs gmime.References
--- @return string
function M.references_get_message_id(refs, index)
	return ffi.string(gmime.g_mime_references_get_message_id(refs, index))
end

--- @param refs gmime.References
--- @param index number
--- @param msgid string
function M.references_set_message_id(refs, index, msgid)
	gmime.g_mime_references_set_message_id(refs, index, msgid)
end

function M.references_format(refs)
	if not refs then
		return nil
	end
	local box = {}
	for ref in M.reference_iter(refs) do
		table.insert(box, "<" .. ref .. ">")
	end
	return table.concat(box, "\n\t")
end

function M.reference_iter_str(str, opts)
	local refs = M.references_parse(opts, str)
	if refs == nil then
		return function ()
			return nil
		end
	end
	return M.reference_iter(refs)
end

function M.reference_iter(refs)
	local i = 0
	return function()
		if i < M.references_length(refs) then
			local ref = M.references_get_message_id(refs, i)
			i = i + 1
			return ref
		end
	end
end

return M
