local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

-- GMimeContentEncoding g_mime_content_encoding_from_string (const char *str);
function M.g_mime_content_encoding_from_string(str)
	return gmime.g_mime_content_encoding_from_string(str)
end
-- const char *g_mime_content_encoding_to_string (GMimeContentEncoding encoding);
function M.g_mime_content_encoding_to_string(encoding)
	return ffi.string(gmime.g_mime_content_encoding_to_string(encoding))
end
-- void g_mime_encoding_init_encode (GMimeEncoding *state, GMimeContentEncoding encoding);
function M.g_mime_encoding_init_encode(state, encoding)
	gmime.g_mime_encoding_init_encode(state, encoding)
end
-- void g_mime_encoding_init_decode (GMimeEncoding *state, GMimeContentEncoding encoding);
function M.g_mime_encoding_init_decode(state, encoding)
	gmime.g_mime_encoding_init_decode(state, encoding)
end
-- void g_mime_encoding_reset (GMimeEncoding *state);
function M.g_mime_encoding_reset(state)
	gmime.g_mime_encoding_reset(state)
end
--
-- size_t g_mime_encoding_outlen (GMimeEncoding *state, size_t inlen);
function M.g_mime_encoding_outlen(state, len)
	return gmime.g_mime_encoding_outlen(state, len)
end
--
-- size_t g_mime_encoding_step (GMimeEncoding *state, const char *inbuf, size_t inlen, char *outbuf);
--- XXX
function M.g_mime_encoding_step()
	return gmime.g_mime_encoding_step()
end

-- size_t g_mime_encoding_flush (GMimeEncoding *state, const char *inbuf, size_t inlen, char *outbuf);
--- XXX
function M.g_mime_encoding_flush()
	return gmime.g_mime_encoding_flush()
end
--
--
-- size_t g_mime_encoding_base64_decode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_base64_decode_step()
	return gmime.g_mime_encoding_base64_decode_step()
end
-- size_t g_mime_encoding_base64_encode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_base64_encode_step()
	return gmime.g_mime_encoding_base64_encode_step()
end
-- size_t g_mime_encoding_base64_encode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_base64_encode_close()
	return gmime.g_mime_encoding_base64_encode_close()
end
--
-- size_t g_mime_encoding_uudecode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_uudecode_step()
	return gmime.g_mime_encoding_uudecode_step()
end
-- size_t g_mime_encoding_uuencode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, unsigned char *uubuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_uuencode_step()
	return gmime.g_mime_encoding_uuencode_step()
end
-- size_t g_mime_encoding_uuencode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, unsigned char *uubuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_uuencode_close()
	return gmime.g_mime_encoding_uuencode_close()
end
--
-- size_t g_mime_encoding_quoted_decode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_quoted_decode_step()
	return gmime.g_mime_encoding_quoted_decode_step()
end
-- size_t g_mime_encoding_quoted_encode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_quoted_encode_step()
	return gmime.g_mime_encoding_quoted_encode_step()
end
-- size_t g_mime_encoding_quoted_encode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
--- XXX
function M.g_mime_encoding_quoted_encode_close()
	return gmime.g_mime_encoding_quoted_encode_close()
end
--
-- iconv_t g_mime_iconv_open (const char *to, const char *from);
function M.g_mime_iconv_open(to, from)
	return gmime.g_mime_iconv_open(to, from)
end
--
-- int g_mime_iconv_close (iconv_t cd);
function M.g_mime_iconv_close(cd)
	return gmime.g_mime_iconv_close(cd)
end
--
-- void        g_mime_charset_map_init (void);
function M.g_mime_charset_map_init()
	gmime.g_mime_charset_map_init()
end

-- void        g_mime_charset_map_shutdown (void);
function M.g_mime_charset_map_shutdown()
	gmime.g_mime_charset_map_shutdown()
end
--
-- const char *g_mime_locale_charset (void);
function M.g_mime_locale_charset()
	return ffi.string(gmime.g_mime_locale_charset())
end
-- const char *g_mime_locale_language (void);
function M.g_mime_locale_language()
	return ffi.string(gmime.g_mime_locale_language())
end
--
-- const char *g_mime_charset_language (const char *charset);
function M.g_mime_charset_language(charset)
	return ffi.string(gmime.g_mime_charset_language(charset))
end
--
-- const char *g_mime_charset_canon_name (const char *charset);
function M.g_mime_charset_canon_name()
	return ffi.string(gmime.g_mime_charset_canon_name())
end
-- const char *g_mime_charset_iconv_name (const char *charset);
function M.g_mime_charset_iconv_name(charset)
	return ffi.string(gmime.g_mime_charset_iconv_name(charset))
end
--
-- const char *g_mime_charset_iso_to_windows (const char *isocharset);
function M.g_mime_charset_iso_to_windows()
	return ffi.string(gmime.g_mime_charset_iso_to_windows()
end
-- void g_mime_charset_init (GMimeCharset *charset);
function M.g_mime_charset_init()
	gmime.g_mime_charset_init()
end
-- void g_mime_charset_step (GMimeCharset *charset, const char *inbuf, size_t inlen);
function M.g_mime_charset_step()
	gmime.g_mime_charset_step()
end
-- const char *g_mime_charset_best_name (GMimeCharset *charset);
function M.g_mime_charset_best_name()
	gmime.g_mime_charset_best_name()
end
--
-- const char *g_mime_charset_best (const char *inbuf, size_t inlen);
function M.g_mime_charset_best()
	gmime.g_mime_charset_best()
end
--
-- gboolean g_mime_charset_can_encode (GMimeCharset *mask, const char *charset,
-- 				    const char *text, size_t len);
function M.g_mime_charset_can_encode()
	return gmime.g_mime_charset_can_encode()
end
--
-- // util functions
-- char *g_mime_iconv_strdup (iconv_t cd, const char *str);
function M.g_mime_iconv_strdup()
	local mem = gmime.g_mime_iconv_strdup()
	return convert.strdup(mem)
end

--- XXX do we need this?
-- char *g_mime_iconv_strndup (iconv_t cd, const char *str, size_t n);
-- function M.g_mime_iconv_strndup()
-- 	g_mime_iconv_strndup()
-- end
--
-- char *g_mime_iconv_locale_to_utf8 (const char *str);
function M.g_mime_iconv_locale_to_utf8()
	local mem = gmime.g_mime_iconv_locale_to_utf8()
	return convert.strdup(mem)
end
-- char *g_mime_iconv_locale_to_utf8_length (const char *str, size_t n);
function M.g_mime_iconv_locale_to_utf8_length()
	local mem = gmime.g_mime_iconv_locale_to_utf8_length()
	return convert.strdup(mem)
end
--
-- char *g_mime_iconv_utf8_to_locale (const char *str);
function M.g_mime_iconv_utf8_to_locale()
	local mem = g_mime_iconv_utf8_to_locale()
	return convert.strdup(mem)
end
-- char *g_mime_iconv_utf8_to_locale_length (const char *str, size_t n);
function M.g_mime_iconv_utf8_to_locale_length()
	local mem = g_mime_iconv_utf8_to_locale_length()
	return convert.strdup(mem)
end
--
-- typedef void (* GMimeObjectForeachFunc) (GMimeObject *parent, GMimeObject *part, gpointer user_data);
--
-- // void g_mime_object_register_type (const char *type, const char *subtype, GType object_type);
--
-- GMimeObject *g_mime_object_new (GMimeParserOptions *options, GMimeContentType *content_type);
function M.g_mime_object_new()
	return gime.g_mime_object_new()
end

-- GMimeObject *g_mime_object_new_type (GMimeParserOptions *options, const char *type, const char *subtype);
function M.g_mime_object_new_type()
	return gmime.g_mime_object_new_type()
end
--
-- void g_mime_object_set_content_type (GMimeObject *object, GMimeContentType *content_type);
function M.g_mime_object_set_content_type()
	gmime.g_mime_object_set_content_type()
end
-- GMimeContentType *g_mime_object_get_content_type (GMimeObject *object);
function M.g_mime_object_get_content_type()
	return gmime.g_mime_object_get_content_type()
end
-- void g_mime_object_set_content_type_parameter (GMimeObject *object, const char *name, const char *value);
function M.g_mime_object_set_content_type_parameter()
	gmime.g_mime_object_set_content_type_parameter()
end
-- const char *g_mime_object_get_content_type_parameter (GMimeObject *object, const char *name);
function M.g_mime_object_get_content_type_parameter()
	return ffi.string(gmime.g_mime_object_get_content_type_parameter())
end
--
-- void g_mime_object_set_content_disposition (GMimeObject *object, GMimeContentDisposition *disposition);
function M.g_mime_object_set_content_disposition()
	gmime.g_mime_object_set_content_disposition()
end
-- GMimeContentDisposition *g_mime_object_get_content_disposition (GMimeObject *object);
function M.g_mime_object_get_content_disposition()
	return gmime.g_mime_object_get_content_disposition()
end
--
-- void g_mime_object_set_disposition (GMimeObject *object, const char *disposition);
function M.g_mime_object_set_disposition()
	gmime.g_mime_object_set_disposition()
end
-- const char *g_mime_object_get_disposition (GMimeObject *object);
function M.g_mime_object_get_disposition()
	return ffi.string(g_mime_object_get_disposition())
end
--
-- void g_mime_object_set_content_disposition_parameter (GMimeObject *object, const char *name, const char *value);
function M.g_mime_object_set_content_disposition_parameter()
	gmime.g_mime_object_set_content_disposition_parameter()
end
-- const char *g_mime_object_get_content_disposition_parameter (GMimeObject *object, const char *name);
function M.g_mime_object_get_content_disposition_parameter()
	return ffi.string(g_mime_object_get_content_disposition_parameter())
end
--
-- void g_mime_object_set_content_id (GMimeObject *object, const char *content_id);
function M.g_mime_object_set_content_id()
	gmime.g_mime_object_set_content_id()
end
-- const char *g_mime_object_get_content_id (GMimeObject *object);
function M.g_mime_object_get_content_id()
	gmime.g_mime_object_get_content_id()
end
--
-- void g_mime_object_prepend_header (GMimeObject *object, const char *header, const char *value, const char *charset);
function M.g_mime_object_prepend_header()
	gmime.g_mime_object_prepend_header()
end
-- void g_mime_object_append_header (GMimeObject *object, const char *header, const char *value, const char *charset);
function M.g_mime_object_append_header()
	gmime.g_mime_object_append_header()
end
-- void g_mime_object_set_header (GMimeObject *object, const char *header, const char *value, const char *charset);
function M.g_mime_object_set_header()
	gmime.g_mime_object_set_header()
end
-- const char *g_mime_object_get_header (GMimeObject *object, const char *header);
function M.g_mime_object_get_header()
	return ffi.string(gmime.g_mime_object_get_header())
end
-- gboolean g_mime_object_remove_header (GMimeObject *object, const char *header);
function M.g_mime_object_remove_header()
	return gmime.g_mime_object_remove_header()
end
--
-- GMimeHeaderList *g_mime_object_get_header_list (GMimeObject *object);
function M.g_mime_object_get_header_list()
	return gmime.g_mime_object_get_header_list()
end
--
-- char *g_mime_object_get_headers (GMimeObject *object, GMimeFormatOptions *options);
function M.g_mime_object_get_headers()
	local mem = g_mime_object_get_headers()
	return convert.strdup(mem)
end

--
-- ssize_t g_mime_object_write_to_stream (GMimeObject *object, GMimeFormatOptions *options, GMimeStream *stream);
function M.g_mime_object_write_to_stream()
	return gmime.g_mime_object_write_to_stream()
end
-- ssize_t g_mime_object_write_content_to_stream (GMimeObject *object, GMimeFormatOptions *options, GMimeStream *stream);
function M.g_mime_object_write_content_to_stream()
	return gmime.g_mime_object_write_content_to_stream()
end
-- char *g_mime_object_to_string (GMimeObject *object, GMimeFormatOptions *options);
function M.g_mime_object_to_string()
	local mem = gmime.g_mime_object_to_string()
	return convert.strdup(mem)
end
--
-- void g_mime_object_encode (GMimeObject *object, GMimeEncodingConstraint constraint);
function M.g_mime_object_encode()
	gmime.g_mime_object_encode()
end
-- void g_object_unref (gpointer object);
function M.g_object_unref()
	gmime.g_object_unref()
end

return M
