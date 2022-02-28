local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

-- GMimeContentEncoding g_mime_content_encoding_from_string (const char *str);
--- @param str string
--- @return gmime.ContentEncoding
function M.content_encoding_from_string(str)
	return gmime.g_mime_content_encoding_from_string(str)
end

-- const char *g_mime_content_encoding_to_string (GMimeContentEncoding encoding);
--- @param encoding gmime.ContentEncoding
--- @return string
function M.content_encoding_to_string(encoding)
	return ffi.string(gmime.g_mime_content_encoding_to_string(encoding))
end

--- @param state gmime.EncodingState
--- @param encoding gmime.ContentEncoding
function M.encoding_init_encode(state, encoding)
	gmime.g_mime_encoding_init_encode(state, encoding)
end

-- void g_mime_encoding_init_decode (GMimeEncoding *state, GMimeContentEncoding encoding);
--- @param state gmime.EncodingState
--- @param encoding gmime.ContentEncoding
function M.encoding_init_decode(state, encoding)
	gmime.g_mime_encoding_init_decode(state, encoding)
end

-- void g_mime_encoding_reset (GMimeEncoding *state);
--- @param state gmime.EncodingState
function M.encoding_reset(state)
	gmime.g_mime_encoding_reset(state)
end
--
-- size_t g_mime_encoding_outlen (GMimeEncoding *state, size_t inlen);
--- @param state gmime.EncodingState
function M.encoding_outlen(state, len)
	return gmime.g_mime_encoding_outlen(state, len)
end
--
-- size_t g_mime_encoding_step (GMimeEncoding *state, const char *inbuf, size_t inlen, char *outbuf);
--- XXX
function M.encoding_step()
	return gmime.g_mime_encoding_step()
end

-- size_t g_mime_encoding_flush (GMimeEncoding *state, const char *inbuf, size_t inlen, char *outbuf);
--- XXX
function M.encoding_flush()
	return gmime.g_mime_encoding_flush()
end
--
--
-- size_t g_mime_encoding_base64_decode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_base64_decode_step()
	return gmime.g_mime_encoding_base64_decode_step()
end
-- size_t g_mime_encoding_base64_encode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_base64_encode_step()
	return gmime.g_mime_encoding_base64_encode_step()
end
-- size_t g_mime_encoding_base64_encode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_base64_encode_close()
	return gmime.g_mime_encoding_base64_encode_close()
end
--
-- size_t g_mime_encoding_uudecode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_uudecode_step()
	return gmime.g_mime_encoding_uudecode_step()
end
-- size_t g_mime_encoding_uuencode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, unsigned char *uubuf, int *state, guint32 *save);
--- XXX
function M.encoding_uuencode_step()
	return gmime.g_mime_encoding_uuencode_step()
end
-- size_t g_mime_encoding_uuencode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, unsigned char *uubuf, int *state, guint32 *save);
--- XXX
function M.encoding_uuencode_close()
	return gmime.g_mime_encoding_uuencode_close()
end

-- size_t g_mime_encoding_quoted_decode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_quoted_decode_step()
	return gmime.g_mime_encoding_quoted_decode_step()
end

-- size_t g_mime_encoding_quoted_encode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_quoted_encode_step()
	return gmime.g_mime_encoding_quoted_encode_step()
end

-- size_t g_mime_encoding_quoted_encode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.encoding_quoted_encode_close()
	return gmime.g_mime_encoding_quoted_encode_close()
end

-- iconv_t g_mime_iconv_open (const char *to, const char *from);
--- @param to string
--- @param from string
--- @return iconv
function M.iconv_open(to, from)
	return gmime.g_mime_iconv_open(to, from)
end

-- int g_mime_iconv_close (iconv_t cd);
--- @param cd iconv
--- @return number
function M.iconv_close(cd)
	return gmime.g_mime_iconv_close(cd)
end

-- void        g_mime_charset_map_init (void);
function M.charset_map_init()
	gmime.g_mime_charset_map_init()
end

-- void        g_mime_charset_map_shutdown (void);
function M.charset_map_shutdown()
	gmime.g_mime_charset_map_shutdown()
end

-- const char *g_mime_locale_charset (void);
--- @return string
function M.locale_charset()
	return ffi.string(gmime.g_mime_locale_charset())
end

-- const char *g_mime_locale_language (void);
--- @return string
function M.locale_language()
	return ffi.string(gmime.g_mime_locale_language())
end

-- const char *g_mime_charset_language (const char *charset);
--- @param charset string
--- @return string
function M.charset_language(charset)
	return ffi.string(gmime.g_mime_charset_language(charset))
end

-- const char *g_mime_charset_canon_name (const char *charset);
--- @param charset string
--- @return string
function M.charset_canon_name(charset)
	return ffi.string(gmime.g_mime_charset_canon_name(charset))
end

-- const char *g_mime_charset_iconv_name (const char *charset);
--- @param charset string
--- @return string
function M.charset_iconv_name(charset)
	return ffi.string(gmime.g_mime_charset_iconv_name(charset))
end

-- const char *g_mime_charset_iso_to_windows (const char *isocharset);
--- @param isocharset string
--- @return string
function M.charset_iso_to_windows(isocharset)
	return ffi.string(gmime.g_mime_charset_iso_to_windows(isocharset))
end

-- void g_mime_charset_init (GMimeCharset *charset);
function M.charset_init(charset)
	gmime.g_mime_charset_init(charset)
end

-- void g_mime_charset_step (GMimeCharset *charset, const char *inbuf, size_t inlen);
--- XXX
function M.charset_step()
	gmime.g_mime_charset_step()
end

-- const char *g_mime_charset_best_name (GMimeCharset *charset);
--- XXX
function M.charset_best_name()
	gmime.g_mime_charset_best_name()
end

-- const char *g_mime_charset_best (const char *inbuf, size_t inlen);
--- XXX
function M.charset_best()
	gmime.g_mime_charset_best()
end
--
-- gboolean g_mime_charset_can_encode (GMimeCharset *mask, const char *charset,
-- 				    const char *text, size_t len);
--- XXX
function M.charset_can_encode()
	return gmime.g_mime_charset_can_encode()
end
--
-- // util functions
-- char *g_mime_iconv_strdup (iconv_t cd, const char *str);
--- XXX
function M.iconv_strdup()
	local mem = gmime.g_mime_iconv_strdup()
	return convert.strdup(mem)
end

--- XXX do we need this?
-- char *g_mime_iconv_strndup (iconv_t cd, const char *str, size_t n);
-- function M.iconv_strndup()
-- 	g_mime_iconv_strndup()
-- end

-- char *g_mime_iconv_locale_to_utf8 (const char *str);
--- @param str string
--- @return string
function M.iconv_locale_to_utf8(str)
	local mem = gmime.g_mime_iconv_locale_to_utf8(str)
	return convert.strdup(mem)
end

-- char *g_mime_iconv_locale_to_utf8_length (const char *str, size_t n);
--- @param str string
--- @param length number
--- @return string
function M.iconv_locale_to_utf8_length(str, length)
	local mem = gmime.g_mime_iconv_locale_to_utf8_length(str, length)
	return convert.strdup(mem)
end

-- char *g_mime_iconv_utf8_to_locale (const char *str);
--- @param str string
--- @return string
function M.iconv_utf8_to_locale(str)
	local mem = gmime.g_mime_iconv_utf8_to_locale(str)
	return convert.strdup(mem)
end

-- char *g_mime_iconv_utf8_to_locale_length (const char *str, size_t n);
--- @param str string
--- @param length number
--- @return string
function M.iconv_utf8_to_locale_length(str, length)
	local mem = gmime.g_mime_iconv_utf8_to_locale_length(str, length)
	return convert.strdup(mem)
end
--
-- typedef void (* GMimeObjectForeachFunc) (GMimeObject *parent, GMimeObject *part, gpointer user_data);
--
-- // void g_mime_object_register_type (const char *type, const char *subtype, GType object_type);

-- GMimeObject *g_mime_object_new (GMimeParserOptions *options, GMimeContentType *content_type);

--- @param options gmime.ParserOptions
--- @param content_type gmime.ContentType
--- @return gmime.MimeObject
function M.mime_object_new(options, content_type)
	return ffi.gc(gmime.g_mime_object_new(options, content_type), gmime.g_object_unref)
end

-- GMimeObject *g_mime_object_new_type (GMimeParserOptions *options, const char *type, const char *subtype);
--- @param options gmime.ParserOptions
--- @param type string
--- @param subtype string
--- @return gmime.MimeObject
function M.object_new_type(options, type, subtype)
	return ffi.gc(gmime.g_mime_object_new_type(options, type, subtype), gmime.g_object_unref)
end

-- void g_mime_object_set_content_type (GMimeObject *object, GMimeContentType *content_type);
--- @param object gmime.MimeObject
--- @param content_type gmime.ContentType
function M.object_set_content_type(object, content_type)
	gmime.g_mime_object_set_content_type(object, content_type)
end

-- GMimeContentType *g_mime_object_get_content_type (GMimeObject *object);
--- @param object gmime.MimeObject
--- @return gmime.ContentType
function M.object_get_content_type(object)
	return gmime.g_mime_object_get_content_type(object)
end

-- void g_mime_object_set_content_type_parameter (GMimeObject *object, const char *name, const char *value);
--- @param object gmime.MimeObject
--- @param name string
--- @param value string
function M.object_set_content_type_parameter(object, name, value)
	gmime.g_mime_object_set_content_type_parameter(object, name, value)
end

-- const char *g_mime_object_get_content_type_parameter (GMimeObject *object, const char *name);
--- @param object gmime.MimeObject
--- @param name string
function M.object_get_content_type_parameter(object, name)
	return ffi.string(gmime.g_mime_object_get_content_type_parameter(object, name))
end

-- void g_mime_object_set_content_disposition (GMimeObject *object, GMimeContentDisposition *disposition);
--- @param object gmime.MimeObject
--- @param disposition gmime.ContentDisposition
function M.object_set_content_disposition(object, disposition)
	gmime.g_mime_object_set_content_disposition(object, disposition)
end

-- GMimeContentDisposition *g_mime_object_get_content_disposition (GMimeObject *object);
--- @param object gmime.MimeObject
--- @return gmime.ContentDisposition
function M.object_get_content_disposition(object)
	return gmime.g_mime_object_get_content_disposition(object)
end

-- void g_mime_object_set_disposition (GMimeObject *object, const char *disposition);
--- @param object gmime.MimeObject
--- @param disposition string
function M.object_set_disposition(object, disposition)
	gmime.g_mime_object_set_disposition(object, disposition)
end

-- const char *g_mime_object_get_disposition (GMimeObject *object);
--- @param object gmime.MimeObject
--- @return string
function M.object_get_disposition(object)
	return ffi.string(gmime.g_mime_object_get_disposition(object))
end

-- void g_mime_object_set_content_disposition_parameter (GMimeObject *object, const char *name, const char *value);
--- @param object gmime.MimeObject
--- @param name string
--- @param value string
function M.object_set_content_disposition_parameter(object, name, value)
	gmime.g_mime_object_set_content_disposition_parameter(object, name, value)
end

-- const char *g_mime_object_get_content_disposition_parameter (GMimeObject *object, const char *name);
--- @param object gmime.MimeObject
--- @param name string
--- @return string
function M.object_get_content_disposition_parameter(object, name)
	return ffi.string(gmime.g_mime_object_get_content_disposition_parameter(object, name))
end

-- void g_mime_object_set_content_id (GMimeObject *object, const char *content_id);
--- @param object gmime.MimeObject
--- @param content_id string
function M.object_set_content_id(object, content_id)
	gmime.g_mime_object_set_content_id(object, content_id)
end

-- const char *g_mime_object_get_content_id (GMimeObject *object);
--- @param object gmime.MimeObject
--- @return string
function M.object_get_content_id(object)
	gmime.g_mime_object_get_content_id(object)
end

-- void g_mime_object_prepend_header (GMimeObject *object, const char *header, const char *value, const char *charset);
--- @param object gmime.MimeObject
function M.object_prepend_header(object, header, value, charset)
	gmime.g_mime_object_prepend_header(object, header, value, charset)
end

-- void g_mime_object_append_header (GMimeObject *object, const char *header, const char *value, const char *charset);
--- @param object gmime.MimeObject
--- @param header string
--- @param value string
--- @param charset string
function M.object_append_header(object, header, value, charset)
	gmime.g_mime_object_append_header(object, header, value, charset)
end

-- void g_mime_object_set_header (GMimeObject *object, const char *header, const char *value, const char *charset);
--- @param object gmime.MimeObject
--- @param header string
--- @param value string
--- @param charset string
function M.object_set_header(object, header, value, charset)
	gmime.g_mime_object_set_header(object, header, value, charset)
end

-- const char *g_mime_object_get_header (GMimeObject *object, const char *header);
--- @param object gmime.MimeObject
--- @param header string
--- @return string
function M.object_get_header(object, header)
	return ffi.string(gmime.g_mime_object_get_header(object, header))
end

-- gboolean g_mime_object_remove_header (GMimeObject *object, const char *header);
--- @param object gmime.MimeObject
--- @param header string
--- @return boolean
function M.object_remove_header(object, header)
	return gmime.g_mime_object_remove_header(object, header) ~= 0
end

-- GMimeHeaderList *g_mime_object_get_header_list (GMimeObject *object);
--- @param object gmime.MimeObject
--- @return gmime.HeaderList
function M.object_get_header_list(object)
	return gmime.g_mime_object_get_header_list(object)
end

-- char *g_mime_object_get_headers (GMimeObject *object, GMimeFormatOptions *options);
--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @return string
function M.object_get_headers(object, options)
	local mem = gmime.g_mime_object_get_headers(object, options)
	return convert.strdup(mem)
end

-- ssize_t g_mime_object_write_to_stream (GMimeObject *object, GMimeFormatOptions *options, GMimeStream *stream);
--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @param stream gmime.Stream
--- @return number
function M.object_write_to_stream(object, options, stream)
	return gmime.g_mime_object_write_to_stream(object, options, stream)
end

-- ssize_t g_mime_object_write_content_to_stream (GMimeObject *object, GMimeFormatOptions *options, GMimeStream *stream);
--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @param stream gmime.Stream
--- @return number
function M.object_write_content_to_stream(object, options, stream)
	return gmime.g_mime_object_write_content_to_stream(object, options, stream)
end

-- char *g_mime_object_to_string (GMimeObject *object, GMimeFormatOptions *options);
--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @return number
function M.object_to_string(object, options)
	local mem = gmime.g_mime_object_to_string(object, options)
	return convert.strdup(mem)
end

-- void g_mime_object_encode (GMimeObject *object, GMimeEncodingConstraint constraint);
--- @param object gmime.MimeObject
--- @param constraint gmime.EncodingConstraint
function M.object_encode(object, constraint)
	gmime.g_mime_object_encode(object, constraint)
end

-- void g_object_unref (gpointer object);
--- @param object any
function M.g_object_unref(object)
	gmime.g_object_unref(object)
end

return M
