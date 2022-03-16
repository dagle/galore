---@diagnostic disable: undefined-field
local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local safe = require("galore.gmime.funcs")
local ffi = require("ffi")

local M = {}

-- char *g_mime_header_format_content_disposition (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_content_disposition(header, options, value, charset)
	local mem = gmime.g_mime_header_format_content_disposition(header, options, value, charset)
	return safe.strdup(mem)
end

-- char *g_mime_header_format_content_type (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_content_type(header, options, value, charset)
	local mem = gmime.g_mime_header_format_content_type(header, options, value, charset)
	return safe.strdup(mem)
end

-- char *g_mime_header_format_message_id (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_message_id(header, options, value, charset)
	local mem = gmime.g_mime_header_format_message_id(header, options, value, charset)
	return safe.strdup(mem)
end

-- char *g_mime_header_format_references (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_references(header, options, value, charset)
	local mem = gmime.g_mime_header_format_references(header, options, value, charset)
	return safe.strdup(mem)
end

-- char *g_mime_header_format_addrlist (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_addrlist(header, options, value, charset)
	local mem = gmime.g_mime_header_format_addrlist(header, options, value, charset)
	return safe.strdup(mem)
end

-- char *g_mime_header_format_received (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_received(header, options, value, charset)
	local mem = gmime.g_mime_header_format_received(header, options, value, charset)
	return safe.strdup(mem)
end

-- char *g_mime_header_format_default (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_format_default(header, options, value, charset)
	local mem = gmime.g_mime_header_format_default(header, options, value, charset)
	return safe.strdup(mem)
end

--
-- const char *g_mime_header_get_name (GMimeHeader *header);
--- @param header gmime.Header
--- @return string
function M.header_get_name(header)
	return safe.safestring(gmime.g_mime_header_get_name(header))
end

-- const char *g_mime_header_get_raw_name (GMimeHeader *header);
--- @param header gmime.Header
--- @return string
function M.header_get_raw_name(header)
	return ffi.string(gmime.g_mime_header_get_raw_name(header))
end
--
-- const char *g_mime_header_get_value (GMimeHeader *header);
--- @param header gmime.Header
--- @return string
function M.header_get_value(header)
	return safe.safestring(gmime.g_mime_header_get_value(header))
end

-- void g_mime_header_set_value (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param value string
--- @param charset string
--- @return string
function M.header_set_value(header, options, value, charset)
	gmime.g_mime_header_set_value(header, options, value, charset)
end

--
-- const char *g_mime_header_get_raw_value (GMimeHeader *header);
--- @param header gmime.Header
--- @return string
function M.header_get_raw_value(header)
	return ffi.string(gmime.g_mime_header_get_raw_value(header))
end

-- void g_mime_header_set_raw_value (GMimeHeader *header, const char *raw_value);
--- @param header gmime.Header
--- @param raw_value string
function M.header_set_raw_value(header, raw_value)
	gmime.g_mime_header_set_raw_value(header, raw_value)
end

--
-- gint64 g_mime_header_get_offset (GMimeHeader *header);
--- @param header gmime.Header
--- @return number
function M.header_get_offset(header)
	return tonumber(gmime.g_mime_header_get_offset(header))
end

--
-- ssize_t g_mime_header_write_to_stream (GMimeHeader *header, GMimeFormatOptions *options, GMimeStream *stream);
--- @param header gmime.Header
--- @param options gmime.Option
--- @param stream gmime.Stream
--- @return number
function M.header_write_to_stream(header, options, stream)
	return gmime.g_mime_header_write_to_stream(header, options, stream)
end

--
-- GMimeHeaderList *g_mime_header_list_new (GMimeParserOptions *options);
--- @param options gmime.Option
--- @return gmime.HeaderList
function M.header_list_new(options)
	return ffi.gc(gmime.g_mime_header_list_new(options), gmime.g_object_unref)
end

--
-- void g_mime_header_list_clear (GMimeHeaderList *headers);
--- @param headers gmime.HeaderList
function M.header_list_clear(headers)
	gmime.g_mime_header_list_clear(headers)
end

-- int g_mime_header_list_get_count (GMimeHeaderList *headers);
--- @param headers gmime.HeaderList
--- @return number
function M.header_list_get_count(headers)
	return gmime.g_mime_header_list_get_count(headers)
end

-- gboolean g_mime_header_list_contains (GMimeHeaderList *headers, const char *name);
--- @param headers gmime.HeaderList
--- @param name string
--- @return boolean
function M.header_list_contains(headers, name)
	return gmime.g_mime_header_list_contains(headers, name) ~= 0
end

-- void g_mime_header_list_prepend (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_list_prepend(headers, options, value, charset)
	gmime.g_mime_header_list_prepend(headers, options, value, charset)
end

-- void g_mime_header_list_append (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_list_append(headers, options, value, charset)
	gmime.g_mime_header_list_append(headers, options, value, charset)
end

-- void g_mime_header_list_set (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param value string
--- @param charset string
function M.header_list_set(headers, options, value, charset)
	gmime.g_mime_header_list_set(headers, options, value, charset)
end

-- GMimeHeader *g_mime_header_list_get_header (GMimeHeaderList *headers, const char *name);
--- @param headers gmime.HeaderList
--- @param name string
--- @return gmime.Header
function M.header_list_get_header(headers, name)
	return gmime.g_mime_header_list_get_header(headers, name)
end

-- GMimeHeader *g_mime_header_list_get_header_at (GMimeHeaderList *headers, int index);
--- @param headers gmime.HeaderList
--- @param index number
--- @return gmime.Header
function M.header_list_get_header_at(headers, index)
	return gmime.g_mime_header_list_get_header_at(headers, index)
end

-- gboolean g_mime_header_list_remove (GMimeHeaderList *headers, const char *name);
--- @param headers gmime.HeaderList
--- @param index number
--- @return boolean
function M.header_list_remove(headers, index)
	return gmime.g_mime_header_list_remove(headers, index) ~= 0
end

-- void g_mime_header_list_remove_at (GMimeHeaderList *headers, int index);
--- @param headers gmime.HeaderList
--- @param index number
function M.header_list_remove_at(headers, index)
	gmime.g_mime_header_list_remove_at(headers, index)
end

--
-- ssize_t g_mime_header_list_write_to_stream (GMimeHeaderList *headers, GMimeFormatOptions *options, GMimeStream *stream);
--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @param stream gmime.Stream
--- @return number
function M.header_list_write_to_stream(headers, options, stream)
	return tonumber(gmime.g_mime_header_list_write_to_stream(headers, options, stream))
end

-- char *g_mime_header_list_to_string (GMimeHeaderList *headers, GMimeFormatOptions *options);
--- @param headers gmime.HeaderList
--- @param options gmime.Option
--- @return string
function M.header_list_to_string(headers, options)
	local mem = gmime.g_mime_header_list_to_string(headers, options)
	return safe.strdup(mem)
end

--
-- GDateTime *g_mime_utils_header_decode_date (const char *str);
--- XXX FIXME
function M.utils_header_decode_date()
	local date = gmime.g_mime_utils_header_decode_date()
end

--- XXX do I need this?
-- char *g_mime_utils_header_format_date (GDateTime *date);
-- function M.utils_header_format_date()
-- 	g_mime_utils_header_format_date()
-- end

-- char *g_mime_utils_generate_message_id (const char *fqdn);
--- @param fqdn string
--- @return string
function M.utils_generate_message_id(fqdn)
	local mem = gmime.g_mime_utils_generate_message_id(fqdn)
	return safe.strdup(mem)
end

--
-- char *g_mime_utils_decode_message_id (const char *message_id);
--- @param message_id string
--- @return string
function M.utils_decode_message_id(message_id)
	local mem = gmime.g_mime_utils_decode_message_id(message_id)
	return safe.strdup(mem)
end

--
-- char  *g_mime_utils_structured_header_fold (GMimeParserOptions *options, GMimeFormatOptions *format, const char *header);
--- @param options gmime.Option
--- @param format gmime.FormatOptions
--- @param header string
--- @return string
function M.utils_structured_header_fold(options, format, header)
	local mem = gmime.g_mime_utils_structured_header_fold(options, format, header)
	return safe.strdup(mem)
end

-- char  *g_mime_utils_unstructured_header_fold (GMimeParserOptions *options, GMimeFormatOptions *format, const char *header);
--- @param options gmime.Option
--- @param format gmime.FormatOptions
--- @param header string
--- @return string
function M.utils_unstructured_header_fold(options, format, header)
	local mem = gmime.g_mime_utils_unstructured_header_fold(options, format, header)
	return safe.strdup(mem)
end

-- char  *g_mime_utils_header_printf (GMimeParserOptions *options, GMimeFormatOptions *format, const char *text, ...);
function M.utils_header_printf(option, format, text, ...)
	local mem = gmime.g_mime_utils_header_printf(option, format, text, ...)
	return safe.strdup(mem)
end

-- char  *g_mime_utils_header_unfold (const char *value);
--- @param value string
--- @return string
function M.utils_header_unfold(value)
	local mem = gmime.g_mime_utils_header_unfold(value)
	return safe.strdup(mem)
end

--
-- char  *g_mime_utils_quote_string (const char *str);
--- @param str string
--- @return string
function M.utils_quote_string(str)
	local mem = gmime.g_mime_utils_quote_string(str)
	return safe.strdup(mem)
end

-- void   g_mime_utils_unquote_string (char *str);
-- function M.utils_unquote_string()
-- end

--
-- gboolean g_mime_utils_text_is_8bit (const unsigned char *text, size_t len);
--- @param text string
--- @return boolean
--- XXX
function M.utils_text_is_8bit(text)
	return gmime.g_mime_utils_text_is_8bit(text, #text) ~= 0
end

-- GMimeContentEncoding g_mime_utils_best_encoding (const unsigned char *text, size_t len);
--- @param text string
--- @return gmime.ContentEncoding
function M.utils_best_encoding(text)
	return gmime.g_mime_utils_best_encoding(text, #text)
end

--
-- char *g_mime_utils_decode_8bit (GMimeParserOptions *options, const char *text, size_t len);
--- @param options gmime.Option
--- @param text string
--- @return string
--- XXX
function M.utils_decode_8bit(options, text)
	local mem = gmime.g_mime_utils_decode_8bit(options, text, #text)
	return safe.strdup(mem)
end

--
-- char *g_mime_utils_header_decode_text (GMimeParserOptions *options, const char *text);
--- @param options gmime.Option
--- @param text string
--- @return string
function M.utils_header_decode_text(options, text)
	local mem = gmime.g_mime_utils_header_decode_text(options, text)
	return safe.strdup(mem)
end

-- char *g_mime_utils_header_encode_text (GMimeFormatOptions *options, const char *text, const char *charset);
--- @param options gmime.Option
--- @param text string
--- @param charset string
--- @return string
function M.utils_header_encode_text(options, text, charset)
	local mem = gmime.g_mime_utils_header_encode_text(options, text, charset)
	return safe.strdup(mem)
end

--
-- char *g_mime_utils_header_decode_phrase (GMimeParserOptions *options, const char *phrase);
--- @param options gmime.Option
--- @param phrase string
--- @return string
function M.utils_header_decode_phrase(options, phrase)
	local mem = gmime.g_mime_utils_header_decode_phrase(options, phrase)
	return safe.strdup(mem)
end

-- char *g_mime_utils_header_encode_phrase (GMimeFormatOptions *options, const char *phrase, const char *charset);
--- @param options gmime.Option
--- @param phrase string
--- @param charset string
--- @return string
function M.utils_header_encode_phrase(options, phrase, charset)
	local mem = gmime.g_mime_utils_header_encode_phrase(options, phrase, charset)
	return safe.strdup(mem)
end

--
-- void internet_address_set_name (InternetAddress *ia, const char *name);
--- @param ia gmime.InternetAddress
--- @param name string
function M.internet_address_set_name(ia, name)
	gmime.internet_address_set_name(ia, name)
end

-- const char *internet_address_get_name (InternetAddress *ia);
--- @param ia gmime.InternetAddress
--- @return string
function M.internet_address_get_name(ia)
	return safe.safestring(gmime.internet_address_get_name(ia))
end

--
-- void internet_address_set_charset (InternetAddress *ia, const char *charset);
--- @param ia gmime.InternetAddress
--- @param charset string
function M.internet_address_set_charset(ia, charset)
	gmime.internet_address_set_charset(ia, charset)
end

-- const char *internet_address_get_charset (InternetAddress *ia);
--- @param ia gmime.InternetAddress
--- @return string
function M.internet_address_get_charset(ia)
	return ffi.string(gmime.internet_address_get_charset(ia))
end

--
-- char *internet_address_to_string (InternetAddress *ia, GMimeFormatOptions *options, gboolean encode);
--- @param ia gmime.InternetAddress
--- @return string
function M.internet_address_to_string(ia, option, encode)
	local mem = gmime.internet_address_to_string(ia, option, encode)
	return safe.strdup(mem)
end

--
-- InternetAddress *internet_address_mailbox_new (const char *name, const char *addr);
--- @param name string
--- @param addr string
--- @return gmime.InternetAddress
function M.internet_address_mailbox_new(name, addr)
	return ffi.gc(gmime.internet_address_mailbox_new(name, addr), gmime.g_object_unref)
end

--
-- void internet_address_mailbox_set_addr (InternetAddressMailbox *mailbox, const char *addr);
--- @param mb gmime.InternetAddressMailbox
--- @param addr string
function M.internet_address_mailbox_set_addr(mb, addr)
	gmime.internet_address_mailbox_set_addr(mb, addr)
end

-- const char *internet_address_mailbox_get_addr (InternetAddressMailbox *mailbox);
--- @param mb gmime.InternetAddressMailbox
--- @return string
function M.internet_address_mailbox_get_addr(mb)
	return safe.safestring(gmime.internet_address_mailbox_get_addr(mb))
end

-- const char *internet_address_mailbox_get_idn_addr (InternetAddressMailbox *mailbox);
--- @param mb gmime.InternetAddressMailbox
--- @return string
function M.internet_address_mailbox_get_idn_addr(mb)
	ffi.string(gmime.internet_address_mailbox_get_idn_addr(mb))
end

--
-- InternetAddress *internet_address_group_new (const char *name);
--- @param name string
--- @return gmime.InternetAddress
function M.internet_address_group_new(name)
	return ffi.gc(gmime.internet_address_group_new(name), gmime.g_object_unref)
end

--
-- void internet_address_group_set_members (InternetAddressGroup *group, InternetAddressList *members);
--- @param group gmime.InternetAddressGroup
--- @param members gmime.InternetAddressList
function M.internet_address_group_set_members(group, members)
	gmime.internet_address_group_set_members(group, members)
end

-- InternetAddressList *internet_address_group_get_members (InternetAddressGroup *group);
--- @param group gmime.InternetAddressGroup
--- @return gmime.InternetAddressList
function M.internet_address_group_get_members(group)
	return gmime.internet_address_group_get_members(group)
end

--
-- int internet_address_group_add_member (InternetAddressGroup *group, InternetAddress *member);
--- @param group gmime.InternetAddressGroup
--- @param member gmime.InternetAddress
--- @return number
function M.internet_address_group_add_member(group, member)
	return gmime.internet_address_group_add_member(group, member)
end

--
-- InternetAddressList *internet_address_list_new (void);
--- @return gmime.InternetAddressList
function M.internet_address_list_new()
	return ffi.gc(gmime.internet_address_list_new(), gmime.g_object_unref)
end

--
-- int internet_address_list_length (InternetAddressList *list);
--- @param list gmime.InternetAddressList
--- @return number
function M.internet_address_list_length(list)
	return gmime.internet_address_list_length(list)
end

--
-- void internet_address_list_clear (InternetAddressList *list);
--- @param list gmime.InternetAddressList
function M.internet_address_list_clear(list)
	gmime.internet_address_list_clear(list)
end

--
--- @param list gmime.InternetAddressList
--- @param ia gmime.InternetAddress
--- @return number
function M.internet_address_list_add(list, ia)
	return gmime.internet_address_list_add(list, ia)
end

-- void internet_address_list_prepend (InternetAddressList *list, InternetAddressList *prepend);
--- @param list gmime.InternetAddressList
--- @param prepend gmime.InternetAddressList
function M.internet_address_list_prepend(list, prepend)
	gmime.internet_address_list_prepend(list, prepend)
end

-- void internet_address_list_append (InternetAddressList *list, InternetAddressList *append);
--- @param list gmime.InternetAddressList
--- @param append gmime.InternetAddressList
function M.internet_address_list_append(list, append)
	gmime.internet_address_list_append(list, append)
end

-- void internet_address_list_insert (InternetAddressList *list, int index, InternetAddress *ia);
--- @param list gmime.InternetAddressList
--- @param index number
--- @param ia gmime.InternetAddress
function M.internet_address_list_insert(list, index, ia)
	gmime.internet_address_list_insert(list, index, ia)
end

-- gboolean internet_address_list_remove (InternetAddressList *list, InternetAddress *ia);
--- @param list gmime.InternetAddressList
--- @param ia gmime.InternetAddress
--- @return boolean
function M.internet_address_list_remove(list, ia)
	return gmime.internet_address_list_remove(list, ia) ~= 0
end

-- gboolean internet_address_list_remove_at (InternetAddressList *list, int index);
--- @param list gmime.InternetAddressList
--- @param index number
--- @return boolean
function M.internet_address_list_remove_at(list, index)
	return gmime.internet_address_list_remove_at(list, index) ~= 0
end

--
-- gboolean internet_address_list_contains (InternetAddressList *list, InternetAddress *ia);
--- @param list gmime.InternetAddressList
--- @param ia gmime.InternetAddress
--- @return boolean
function M.internet_address_list_contains(list, ia)
	return gmime.internet_address_list_contains(list, ia) ~= 0
end

-- int internet_address_list_index_of (InternetAddressList *list, InternetAddress *ia);
--- @param list gmime.InternetAddressList
--- @param ia list gmime.InternetAddress
--- @return boolean
function M.internet_address_list_index_of(list, ia)
	return gmime.internet_address_list_index_of(list, ia) ~= 0
end

--
-- InternetAddress *internet_address_list_get_address (InternetAddressList *list, int index);
--- @param list gmime.InternetAddressList
--- @param index number
--- @return gmime.InternetAddress
function M.internet_address_list_get_address(list, index)
	return gmime.internet_address_list_get_address(list, index)
end

-- void internet_address_list_set_address (InternetAddressList *list, int index, InternetAddress *ia);
--- @param list gmime.InternetAddressList
--- @param index number
--- @param ia list gmime.InternetAddress
function M.internet_address_list_set_address(list, index, ia)
	return gmime.internet_address_list_set_address(list, index, ia)
end

--
-- char *internet_address_list_to_string (InternetAddressList *list, GMimeFormatOptions *options, gboolean encode);
--- @param list gmime.InternetAddressList
--- @param options gmime.Option
--- @param encode boolean
--- @return string
function M.internet_address_list_to_string(list, options, encode)
	return safe.safestring(gmime.internet_address_list_to_string(list, options, encode))
end

-- void internet_address_list_encode (InternetAddressList *list, GMimeFormatOptions *options, GString *str);
--- @param list gmime.InternetAddressList
--- @param options gmime.Option
function M.internet_address_list_encode(list, options, str)
	gmime.internet_address_list_encode(list, options, str)
end

--
-- InternetAddressList *internet_address_list_parse (GMimeParserOptions *options, const char *str);
--- @param options gmime.Option
--- @param str string
--- @return gmime.InternetAddressList
function M.internet_address_list_parse(options, str)
	return gmime.internet_address_list_parse(options, str)
end

-- int internet_address_is_mailbox(InternetAddress *ia);
---@param ia gmime.InternetAddress
---@return boolean
function M.internet_address_is_mailbox(ia)
	return gmime.internet_address_is_mailbox(ia) ~= 0
end

-- int internet_address_is_group(InternetAddress *ia);
---@param ia gmime.InternetAddress
---@return boolean
function M.internet_address_is_group(ia)
	return gmime.internet_address_is_group(ia) ~= 0
end
--
-- GMimeContentDisposition *g_mime_content_disposition_new (void);
--- @retun gmime.ContentDisposition
function M.content_disposition_new()
	return ffi.gc(gmime.g_mime_content_disposition_new(), gmime.g_object_unref)
end

-- GMimeContentDisposition *g_mime_content_disposition_parse (GMimeParserOptions *options, const char *str);
--- @param options gmime.Option
--- @param str string
--- @retun gmime.ContentDisposition
function M.content_disposition_parse(options, str)
	return gmime.g_mime_content_disposition_parse(options, str)
end

--
-- void g_mime_content_disposition_set_disposition (GMimeContentDisposition *disposition, const char *value);
--- @param disposition gmime.ContentDisposition
--- @param value string
function M.content_disposition_set_disposition(disposition, value)
	gmime.g_mime_content_disposition_parse(disposition, value)
end

-- const char *g_mime_content_disposition_get_disposition (GMimeContentDisposition *disposition);
--- @param disposition gmime.ContentDisposition
--- @return string
function M.content_disposition_get_disposition(disposition)
	ffi.string(gmime.g_mime_content_disposition_get_disposition(disposition))
end

--
-- GMimeParamList *g_mime_content_disposition_get_parameters (GMimeContentDisposition *disposition);
--- @param disposition gmime.ContentDisposition
--- @return gmime.ParamList
function M.content_disposition_get_parameters(disposition)
	return gmime.g_mime_content_disposition_get_parameters(disposition)
end

--
-- void g_mime_content_disposition_set_parameter (GMimeContentDisposition *disposition,
-- 					       const char *name, const char *value);
--- @param disposition gmime.ContentDisposition
--- @param name string
--- @param value string
function M.content_disposition_set_parameter(disposition, name, value)
	gmime.g_mime_content_disposition_set_parameter(disposition, name, value)
end

-- const char *g_mime_content_disposition_get_parameter (GMimeContentDisposition *disposition,
-- 						      const char *name);
--- @param disposition gmime.ContentDisposition
--- @param name string
function M.content_disposition_get_parameter(disposition, name)
	return ffi.string(gmime.g_mime_content_disposition_get_parameter(disposition, name))
end

--
-- gboolean g_mime_content_disposition_is_attachment (GMimeContentDisposition *disposition);
--- @param disposition gmime.ContentDisposition
function M.content_disposition_is_attachment(disposition)
	return gmime.g_mime_content_disposition_is_attachment(disposition)
end

--
-- char *g_mime_content_disposition_encode (GMimeContentDisposition *disposition, GMimeFormatOptions *options);
--- @param disposition gmime.ContentDisposition
--- @param options gmime.FormatOptions
function M.content_disposition_encode(disposition, options)
	return ffi.string(gmime.g_mime_content_disposition_encode(disposition, options))
end

--
-- GMimeContentType *g_mime_content_type_new (const char *type, const char *subtype);
--- @param type string
--- @param subtype string
--- @return gmime.ContentType
function M.content_type_new(type, subtype)
	return ffi.gc(gmime.g_mime_content_type_new(type, subtype), gmime.g_object_unref)
end

-- GMimeContentType *g_mime_content_type_parse (GMimeParserOptions *options, const char *str);
--- @param options gmime.ParserOptions
--- @param str string
--- @return gmime.ContentType
function M.content_type_parse(options, str)
	return gmime.g_mime_content_type_parse(options, str)
end

--
-- char *g_mime_content_type_get_mime_type (GMimeContentType *content_type);
--- @param content_type gmime.ContentType
--- @return string
function M.content_type_get_mime_type(content_type)
	return ffi.string(gmime.g_mime_content_type_get_mime_type(content_type))
end

--
-- char *g_mime_content_type_encode (GMimeContentType *content_type, GMimeFormatOptions *options);
--- @param content_type gmime.ContentType
--- @param options gmime.FormatOptions
--- @return string
function M.content_type_encode(content_type, options)
	return ffi.string(gmime.g_mime_content_type_encode(content_type, options))
end

--
-- gboolean g_mime_content_type_is_type (GMimeContentType *content_type, const char *type, const char *subtype);
--- @param content_type gmime.ContentType
--- @param type string
--- @param subtype string
function M.content_type_is_type(content_type, type, subtype)
	return gmime.g_mime_content_type_is_type(content_type, type, subtype) ~= 0
end

--
-- void g_mime_content_type_set_media_type (GMimeContentType *content_type, const char *type);
--- @param content_type gmime.ContentType
--- @param type string
function M.content_type_set_media_type(content_type, type)
	gmime.g_mime_content_type_set_media_type(content_type, type)
end

-- const char *g_mime_content_type_get_media_type (GMimeContentType *content_type);
--- @param content_type gmime.ContentType
--- @return string
function M.content_type_get_media_type(content_type)
	return ffi.string(gmime.g_mime_content_type_get_media_type(content_type))
end

--
-- void g_mime_content_type_set_media_subtype (GMimeContentType *content_type, const char *subtype);
--- @param content_type gmime.ContentType
--- @param subtype string
function M.content_type_set_media_subtype(content_type, subtype)
	gmime.g_mime_content_type_set_media_subtype(content_type, subtype)
end

-- const char *g_mime_content_type_get_media_subtype (GMimeContentType *content_type);
--- @param content_type gmime.ContentType
--- @return string
function M.content_type_get_media_subtype(content_type)
	return ffi.string(gmime.g_mime_content_type_get_media_subtype(content_type))
end

--
-- GMimeParamList *g_mime_content_type_get_parameters (GMimeContentType *content_type);
--- @param content_type gmime.ContentType
--- @return gmime.ParamList
function M.content_type_get_parameters(content_type)
	return gmime.g_mime_content_type_get_parameters(content_type)
end

--
-- void g_mime_content_type_set_parameter (GMimeContentType *content_type, const char *name, const char *value);
--- @param content_type gmime.ContentType
--- @param name string
--- @param value string
function M.content_type_set_parameter(content_type, name, value)
	gmime.g_mime_content_type_set_parameter(content_type, name, value)
end

-- const char *g_mime_content_type_get_parameter (GMimeContentType *content_type, const char *name);
--- @param content_type gmime.ContentType
--- @param name string
--- @return string
function M.content_type_get_parameter(content_type, name)
	return ffi.string(gmime.g_mime_content_type_get_parameter(content_type, name))
end

--
-- GMimeReferences *g_mime_references_new (void);
--- @return gmime.References
function M.references_new()
	return ffi.gc(gmime.g_mime_references_new(), M.references_free)
end

-- void g_mime_references_free (GMimeReferences *refs);
--- @param refs gmime.References
function M.references_free(refs)
	gmime.g_mime_references_free(refs)
end

--
-- GMimeReferences *g_mime_references_parse (GMimeParserOptions *options, const char *text);
--- @param options gmime.ParserOptions
--- @param text string
--- @return gmime.References
function M.references_parse(options, text)
	return ffi.gc(gmime.g_mime_references_parse(options, text), M.references_free)
end

--
-- GMimeReferences *g_mime_references_copy (GMimeReferences *refs);
--- @param refs gmime.References
function M.references_copy(refs)
	return gmime.g_mime_references_copy(refs)
end

--
-- int g_mime_references_length (GMimeReferences *refs);
--- @param refs gmime.References
function M.references_length(refs)
	return gmime.g_mime_references_length(refs)
end

--
-- void g_mime_references_append (GMimeReferences *refs, const char *msgid);
--- @param refs gmime.References
--- @param msgid string
function M.references_append(refs, msgid)
	gmime.g_mime_references_append(refs, msgid)
end

-- void g_mime_references_clear (GMimeReferences *refs);
--- @param refs gmime.References
function M.references_clear(refs)
	gmime.g_mime_references_clear(refs)
end

--
-- const char *g_mime_references_get_message_id (GMimeReferences *refs, int index);
--- @param refs gmime.References
--- @return string
function M.references_get_message_id(refs, index)
	return ffi.string(gmime.g_mime_references_get_message_id(refs, index))
end

-- void g_mime_references_set_message_id (GMimeReferences *refs, int index, const char *msgid);
--- @param refs gmime.References
--- @param index number
--- @param msgid string
function M.references_set_message_id(refs, index, msgid)
	gmime.g_mime_references_set_message_id(refs, index, msgid)
end

function M.references_format(refs)
	local box = {}
	for ref in M.reference_iter(refs) do
		table.insert(box, "<" .. ref .. ">")
	end
	return table.concat(box, "\n\t")
end

function M.reference_iter_str(str)
	local refs = M.references_parse(nil, str)
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
