local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

-- char *g_mime_header_format_content_disposition (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_content_disposition(header, option, value, charset)
	local mem = gmime.g_mime_header_format_content_disposition(header, option, value, charset)
	return convert.strdup(mem)
end

-- char *g_mime_header_format_content_type (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_content_type(header, options, value, charset)
	local mem = gmime.g_mime_header_format_content_type(header, options, value, charset)
	return convert.strdup(mem)
end

-- char *g_mime_header_format_message_id (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_message_id(header, options, value, charset)
	local mem = gmime.g_mime_header_format_message_id(header, options, value, charset)
	return convert.strdup(mem)
end

-- char *g_mime_header_format_references (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_references(header, options, value, charset)
	local mem = gmime.g_mime_header_format_references(header, options, value, charset)
	return convert.strdup(mem)
end

-- char *g_mime_header_format_addrlist (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_addrlist(header, options, value, charset)
	local mem = gmime.g_mime_header_format_addrlist(header, options, value, charset)
	return convert.strdup(mem)
end

-- char *g_mime_header_format_received (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_received(header, options, value, charset)
	local mem = gmime.g_mime_header_format_received(header, options, value, charset)
	return convert.strdup(mem)
end

-- char *g_mime_header_format_default (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_format_default(header, options, value, charset)
	local mem = gmime.g_mime_header_format_default(header, options, value, charset)
	return convert.strdup(mem)
end

--
-- const char *g_mime_header_get_name (GMimeHeader *header);
function M.header_get_name(header)
	return ffi.string(gmime.constg_mime_header_get_name(header))
end

-- const char *g_mime_header_get_raw_name (GMimeHeader *header);
function M.header_get_raw_name(header)
	return ffi.string(gmime.g_mime_header_get_raw_name(header))
end
--
-- const char *g_mime_header_get_value (GMimeHeader *header);
function M.header_get_value(header)
	return ffi.string(gmime.g_mime_header_get_value(header))
end

-- void g_mime_header_set_value (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
function M.header_set_value(header, options, value, charset)
	gmime.g_mime_header_set_value(header, options, value, charset)
end

--
-- const char *g_mime_header_get_raw_value (GMimeHeader *header);
function M.header_get_raw_value(header)
	return ffi.string(gmime.g_mime_header_get_raw_value(header))
end

-- void g_mime_header_set_raw_value (GMimeHeader *header, const char *raw_value);
function M.header_set_raw_value(header, raw_value)
	gmime.g_mime_header_set_raw_value(header)
end

--
-- gint64 g_mime_header_get_offset (GMimeHeader *header);
function M.header_get_offset(header)
	return gmime.g_mime_header_get_offset(header)
end

--
-- ssize_t g_mime_header_write_to_stream (GMimeHeader *header, GMimeFormatOptions *options, GMimeStream *stream);
function M.header_write_to_stream(header, options, value, charset)
	return gmime.g_mime_header_write_to_stream(header, options, value, charset)
end

--
-- GMimeHeaderList *g_mime_header_list_new (GMimeParserOptions *options);
function M.header_list_new(option)
	return gmime.g_mime_header_list_new(option)
end

--
-- void g_mime_header_list_clear (GMimeHeaderList *headers);
function M.header_list_clear(headers)
	gmime.g_mime_header_list_clear(headers)
end

-- int g_mime_header_list_get_count (GMimeHeaderList *headers);
function M.header_list_get_count(headers)
	return gmime.g_mime_header_list_get_count(headers)
end

-- gboolean g_mime_header_list_contains (GMimeHeaderList *headers, const char *name);
function M.header_list_contains(headers, name)
	return gmime.g_mime_header_list_contains(headers, name)
end

-- void g_mime_header_list_prepend (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
function M.header_list_prepend(headers, options, value, charset)
	gmime.g_mime_header_list_prepend(header, options, value, charset)
end

-- void g_mime_header_list_append (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
function M.header_list_append(headers, options, value, charset)
	gmime.g_mime_header_list_append(header, options, value, charset)
end

-- void g_mime_header_list_set (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
function M.header_list_set(headers, options, value, charset)
	gmime.g_mime_header_list_set(header, options, value, charset)
end

-- GMimeHeader *g_mime_header_list_get_header (GMimeHeaderList *headers, const char *name);
function M.header_list_get_header(headers, name)
	return gmime.g_mime_header_list_get_header(headers, name)
end

-- GMimeHeader *g_mime_header_list_get_header_at (GMimeHeaderList *headers, int index);
function M.header_list_get_header_at(headers, index)
	return g_mime_header_list_get_header_at(headers, index)
end

-- gboolean g_mime_header_list_remove (GMimeHeaderList *headers, const char *name);
function M.header_list_remove(headers, index)
	return g_mime_header_list_remove(headers, index)
end

-- void g_mime_header_list_remove_at (GMimeHeaderList *headers, int index);
function M.header_list_remove_at(headers, index)
	gmime.g_mime_header_list_remove_at(headers, index)
end

--
-- ssize_t g_mime_header_list_write_to_stream (GMimeHeaderList *headers, GMimeFormatOptions *options, GMimeStream *stream);
function M.header_list_write_to_stream(headers, options, stream)
	return tonumber(gmime.g_mime_header_list_write_to_stream(headers, options, stream))
end

-- char *g_mime_header_list_to_string (GMimeHeaderList *headers, GMimeFormatOptions *options);
function M.header_list_to_string(headers, options)
	local mem = gmime.g_mime_header_list_to_string(headers, options)
	return convert.strdup(mem)
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
function M.utils_generate_message_id(fqdn)
	local mem = gmime.g_mime_utils_generate_message_id(fqdn)
	return convert.strdup(mem)
end

--
-- char *g_mime_utils_decode_message_id (const char *message_id);
function M.utils_decode_message_id(message_id)
	local mem = gmime.g_mime_utils_decode_message_id(message_id)
	return convert.strdup(mem)
end

--
-- char  *g_mime_utils_structured_header_fold (GMimeParserOptions *options, GMimeFormatOptions *format, const char *header);
function M.utils_structured_header_fold(option, format, header)
	local mem = gmime.g_mime_utils_structured_header_fold(option, format, header)
	return convert.strdup(mem)
end

-- char  *g_mime_utils_unstructured_header_fold (GMimeParserOptions *options, GMimeFormatOptions *format, const char *header);
function M.utils_unstructured_header_fold(option, format, header)
	local mem = gmime.g_mime_utils_unstructured_header_fold(option, format, header)
	return convert.strdup(mem)
end

-- char  *g_mime_utils_header_printf (GMimeParserOptions *options, GMimeFormatOptions *format, const char *text, ...);
function M.utils_header_printf(option, format, text, ...)
	local mem = gmime.g_mime_utils_header_printf(option, format, text, ...)
	return convert.strdup(mem)
end

-- char  *g_mime_utils_header_unfold (const char *value);
function M.utils_header_unfold(value)
	local mem = gmime.g_mime_utils_header_unfold(value)
	return convert.strdup(mem)
end

--
-- char  *g_mime_utils_quote_string (const char *str);
function M.utils_quote_string(str)
	local mem = gmime.g_mime_utils_quote_string(str)
	return convert.strdup(mem)
end

-- void   g_mime_utils_unquote_string (char *str);
-- function M.utils_unquote_string()
-- end

--
-- gboolean g_mime_utils_text_is_8bit (const unsigned char *text, size_t len);
function M.utils_text_is_8bit(text)
	return gmime.g_mime_utils_text_is_8bit(text, #text)
end

-- GMimeContentEncoding g_mime_utils_best_encoding (const unsigned char *text, size_t len);
function M.utils_best_encoding(text)
	return gmime.g_mime_utils_best_encoding(text, #text)
end

--
-- char *g_mime_utils_decode_8bit (GMimeParserOptions *options, const char *text, size_t len);
function M.utils_decode_8bit(option, text)
	local mem = gmime.g_mime_utils_decode_8bit(option, text, #text)
	return convert.strdup(mem)
end

--
-- char *g_mime_utils_header_decode_text (GMimeParserOptions *options, const char *text);
function M.utils_header_decode_text(option, text)
	local mem = gmime.g_mime_utils_header_decode_text(options, tetxt)
	return convert.strdup(mem)
end

-- char *g_mime_utils_header_encode_text (GMimeFormatOptions *options, const char *text, const char *charset);
function M.utils_header_encode_text(option, text)
	local mem = gmime.g_mime_utils_header_encode_text(option, text)
	return convert.strdup(mem)
end

--
-- char *g_mime_utils_header_decode_phrase (GMimeParserOptions *options, const char *phrase);
function M.utils_header_decode_phrase(option, phrase)
	local mem = gmime.g_mime_utils_header_decode_phrase(option, phrase)
	return convert.strdup(mem)
end

-- char *g_mime_utils_header_encode_phrase (GMimeFormatOptions *options, const char *phrase, const char *charset);
function M.utils_header_encode_phrase(option, phrase)
	local mem = gmime.g_mime_utils_header_encode_phrase(option, phrase)
	return convert.strdup(mem)
end

--
-- void internet_address_set_name (InternetAddress *ia, const char *name);
function M.internet_address_set_name(ia, name)
	gmime.internet_address_set_name(ia, name)
end

-- const char *internet_address_get_name (InternetAddress *ia);
function M.internet_address_set_name(ia)
	return ffi.string(gmime.g_mime_utils_header_encode_phrase(ia))
end

--
-- void internet_address_set_charset (InternetAddress *ia, const char *charset);
function M.internet_address_set_charset(ia, charset)
	gmime.internet_address_set_charset(ia, charset)
end

-- const char *internet_address_get_charset (InternetAddress *ia);
function M.internet_address_get_charset(ia)
	return ffi.string(gmime.internet_address_get_charset(ia))
end

--
-- char *internet_address_to_string (InternetAddress *ia, GMimeFormatOptions *options, gboolean encode);
function M.internet_address_to_string(ia, option, encode)
	local mem = gmime.internet_address_to_string(ia, option, encode)
	return convert.strdup(mem)
end

--
-- InternetAddress *internet_address_mailbox_new (const char *name, const char *addr);
function M.internet_address_mailbox_new(name, addr)
	return gmime.internet_address_mailbox_new(name, addr)
end

--
-- void internet_address_mailbox_set_addr (InternetAddressMailbox *mailbox, const char *addr);
function M.internet_address_mailbox_set_addr(mb, addr)
	gmime.internet_address_mailbox_set_addr(mb, addr)
end

-- const char *internet_address_mailbox_get_addr (InternetAddressMailbox *mailbox);
function M.internet_address_mailbox_get_addr(mb)
	ffi.string(gmime.internet_address_mailbox_get_addr(mb))
end

-- const char *internet_address_mailbox_get_idn_addr (InternetAddressMailbox *mailbox);
function M.internet_address_mailbox_get_idn_addr(mb)
	ffi.string(gmime.internet_address_mailbox_get_idn_addr(mb))
end

--
-- InternetAddress *internet_address_group_new (const char *name);
function M.internet_address_group_new(name)
	return gmime.internet_address_group_new(name)
end

--
-- void internet_address_group_set_members (InternetAddressGroup *group, InternetAddressList *members);
function M.internet_address_group_set_members(group, members)
	gmime.internet_address_group_new(group, members)
end

-- InternetAddressList *internet_address_group_get_members (InternetAddressGroup *group);
function M.internet_address_group_get_members(group)
	return gmime.internet_address_group_get_members(group)
end

--
-- int internet_address_group_add_member (InternetAddressGroup *group, InternetAddress *member);
function M.internet_address_group_add_member(group, member)
	return gmime.internet_address_group_add_member(group, member)
end

--
-- InternetAddressList *internet_address_list_new (void);
function M.internet_address_list_new()
	return gmime.internet_address_list_new()
end

--
-- int internet_address_list_length (InternetAddressList *list);
function M.internet_address_list_length(list)
	return gmime.internet_address_list_length(list)
end

--
-- void internet_address_list_clear (InternetAddressList *list);
function M.internet_address_list_clear(list)
	gmime.internet_address_list_clear(list)
end

--
-- int internet_address_list_add (InternetAddressList *list, InternetAddress *ia);
function M.internet_address_list_add(list, ia)
	return gmime.internet_address_list_add(list, ia)
end

-- void internet_address_list_prepend (InternetAddressList *list, InternetAddressList *prepend);
function M.internet_address_list_prepend(list, prepend)
	gmime.internet_address_list_prepend(list, prepend)
end

-- void internet_address_list_append (InternetAddressList *list, InternetAddressList *append);
function M.internet_address_list_append(list, append)
	gmime.internet_address_list_append(list, append)
end

-- void internet_address_list_insert (InternetAddressList *list, int index, InternetAddress *ia);
function M.internet_address_list_insert(list, index, ia)
	gmime.internet_address_list_insert(list, index, ia)
end

-- gboolean internet_address_list_remove (InternetAddressList *list, InternetAddress *ia);
function M.internet_address_list_remove(list, ia)
	return gmime.internet_address_list_remove(list, ia)
end

-- gboolean internet_address_list_remove_at (InternetAddressList *list, int index);
function M.internet_address_list_remove_at(list, index)
	return gmime.internet_address_list_remove_at(list, index)
end

--
-- gboolean internet_address_list_contains (InternetAddressList *list, InternetAddress *ia);
function M.internet_address_list_contains(list, ia)
	return gmime.internet_address_list_contains(list, ia)
end

-- int internet_address_list_index_of (InternetAddressList *list, InternetAddress *ia);
function M.internet_address_list_index_of(list, ia)
	return gmime.internet_address_list_index_of(list, ia)
end

--
-- InternetAddress *internet_address_list_get_address (InternetAddressList *list, int index);
function M.internet_address_list_get_address(list, index)
	return gmime.internet_address_list_get_address(list, index)
end

-- void internet_address_list_set_address (InternetAddressList *list, int index, InternetAddress *ia);
function M.internet_address_list_set_address(list, index, ia)
	return gmime.internet_address_list_set_address(list, index, ia)
end

--
-- char *internet_address_list_to_string (InternetAddressList *list, GMimeFormatOptions *options, gboolean encode);
function M.internet_address_list_to_string(list, option, encode)
	return ffi.string(gmime.internet_address_list_to_string(list, option, encode))
end

-- void internet_address_list_encode (InternetAddressList *list, GMimeFormatOptions *options, GString *str);
function M.internet_address_list_encode(list, option, str)
	gmime.internet_address_list_encode(list, option, str)
end

--
-- InternetAddressList *internet_address_list_parse (GMimeParserOptions *options, const char *str);
function M.internet_address_list_parse(option, str)
	return gmime.internet_address_list_parse(option, str)
end

--
-- GMimeContentDisposition *g_mime_content_disposition_new (void);
function M.content_disposition_new()
	return gmime.g_mime_content_disposition_new()
end

-- GMimeContentDisposition *g_mime_content_disposition_parse (GMimeParserOptions *options, const char *str);
function M.content_disposition_parse(option, str)
	return gmime.g_mime_content_disposition_parse(option, str)
end

--
-- void g_mime_content_disposition_set_disposition (GMimeContentDisposition *disposition, const char *value);
function M.content_disposition_set_disposition(disposition, value)
	gmime.g_mime_content_disposition_parse(disposition, value)
end

-- const char *g_mime_content_disposition_get_disposition (GMimeContentDisposition *disposition);
function M.content_disposition_get_disposition(disposition)
	ffi.string(gmime.g_mime_content_disposition_get_disposition(disposition))
end

--
-- GMimeParamList *g_mime_content_disposition_get_parameters (GMimeContentDisposition *disposition);
function M.content_disposition_get_parameters(disposition)
	return gmime.g_mime_content_disposition_get_parameters(disposition)
end

--
-- void g_mime_content_disposition_set_parameter (GMimeContentDisposition *disposition,
-- 					       const char *name, const char *value);
function M.content_disposition_set_parameter(disposition, name, value)
	gmime.g_mime_content_disposition_set_parameter(disposition, name, value)
end

-- const char *g_mime_content_disposition_get_parameter (GMimeContentDisposition *disposition,
-- 						      const char *name);
function M.content_disposition_get_parameter(disposition, name)
	return ffi.string(gmime.g_mime_content_disposition_get_parameter(disposition, name))
end

--
-- gboolean g_mime_content_disposition_is_attachment (GMimeContentDisposition *disposition);
function M.content_disposition_is_attachment(disposition)
	return gmime.g_mime_content_disposition_is_attachment(disposition)
end

--
-- char *g_mime_content_disposition_encode (GMimeContentDisposition *disposition, GMimeFormatOptions *options);
function M.content_disposition_encode(disposition, option)
	return ffi.string(gmime.g_mime_content_disposition_encode(disposition, option))
end

--
-- GMimeContentType *g_mime_content_type_new (const char *type, const char *subtype);
function M.content_type_new(type, subtype)
	return gmime.g_mime_content_type_new(type, subtype)
end

-- GMimeContentType *g_mime_content_type_parse (GMimeParserOptions *options, const char *str);
function M.content_type_parse(options, str)
	return gmime.g_mime_content_type_parse(type, str)
end

--
-- char *g_mime_content_type_get_mime_type (GMimeContentType *content_type);
function M.content_type_get_mime_type(content_type)
	return ffi.string(gmime.g_mime_content_type_get_mime_type(content_type))
end

--
-- char *g_mime_content_type_encode (GMimeContentType *content_type, GMimeFormatOptions *options);
function M.content_type_encode(content_type, options)
	return ffi.string(gmime.g_mime_content_type_encode(content_type, options))
end

--
-- gboolean g_mime_content_type_is_type (GMimeContentType *content_type, const char *type, const char *subtype);
function M.content_type_is_type(content_type, type, subtype)
	return gmime.g_mime_content_type_is_type(content_type, type, subtype)
end

--
-- void g_mime_content_type_set_media_type (GMimeContentType *content_type, const char *type);
function M.content_type_set_media_type(content_type, type)
	gmime.g_mime_content_type_set_media_type(content_type, type)
end

-- const char *g_mime_content_type_get_media_type (GMimeContentType *content_type);
function M.content_type_get_media_type(content_type)
	return ffi.string(gmime.g_mime_content_type_get_media_type(content_type))
end

--
-- void g_mime_content_type_set_media_subtype (GMimeContentType *content_type, const char *subtype);
function M.content_type_set_media_subtype(content_type, subtype)
	gmime.g_mime_content_type_set_media_subtype(content_type, subtype)
end

-- const char *g_mime_content_type_get_media_subtype (GMimeContentType *content_type);
function M.content_type_get_media_subtype(content_type)
	return ffi.string(gmime.g_mime_content_type_get_media_subtype(content_type))
end

--
-- GMimeParamList *g_mime_content_type_get_parameters (GMimeContentType *content_type);
function M.content_type_get_parameters(content_type)
	return gmime.g_mime_content_type_get_parameters(content_type)
end

--
-- void g_mime_content_type_set_parameter (GMimeContentType *content_type, const char *name, const char *value);
function M.content_type_set_parameter(content_type, name, value)
	gmime.g_mime_content_type_set_parameter(content_type, name, value)
end

-- const char *g_mime_content_type_get_parameter (GMimeContentType *content_type, const char *name);
function M.content_type_get_parameter(content_type, name)
	return ffi.string(gmime.g_mime_content_type_get_parameter(content_type, name))
end

--
-- GMimeReferences *g_mime_references_new (void);
function M.references_new()
	return gmime.g_mime_references_new()
end

-- void g_mime_references_free (GMimeReferences *refs);
function M.references_free(refs)
	gmime.g_mime_references_free(refs)
end

--
-- GMimeReferences *g_mime_references_parse (GMimeParserOptions *options, const char *text);
function M.references_parse(option, text)
	return gmime.g_mime_references_parse(option, text)
end

--
-- GMimeReferences *g_mime_references_copy (GMimeReferences *refs);
function M.references_copy(refs)
	return gmime.g_mime_references_copy(refs)
end

--
-- int g_mime_references_length (GMimeReferences *refs);
function M.references_length(refs)
	return gmime.g_mime_references_length(refs)
end

--
-- void g_mime_references_append (GMimeReferences *refs, const char *msgid);
function M.references_append(refs, msgid)
	gmime.g_mime_references_append(refs, msgid)
end

-- void g_mime_references_clear (GMimeReferences *refs);
function M.references_clear(refs)
	gmime.g_mime_references_clear(refs)
end

--
-- const char *g_mime_references_get_message_id (GMimeReferences *refs, int index);
function M.references_get_message_id(refs, index)
	return ffi.string(gmime.g_mime_references_get_message_id(refs, index))
end

-- void g_mime_references_set_message_id (GMimeReferences *refs, int index, const char *msgid);
function M.references_set_message_id(refs, index, msgid)
	gmime.g_mime_references_set_message_id(refs, index, msgid)
end

--
--
-- function M.reference_parse(options, str)
-- 	return gmime.g_mime_references_parse(options, str)
-- end
--
-- function M.reference_append(ref, msgid)
-- 	return gmime.g_mime_references_append(ref, msgid)
-- end
--
-- function M.new_ref()
-- 	return gmime.g_mime_references_new()
-- end
--
-- dunno if this should actually free it
function M.reference_iterator(ref)
	local i = 0
	return function()
		if i < gmime.g_mime_references_length(ref) then
			local ret = ffi.string(gmime.g_mime_references_get_message_id(ref, i))
			i = i + 1
			return ret
		end
		gmime.g_mime_references_clear(ref)
	end
end

return M
