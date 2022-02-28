local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

-- GMimeFilter *g_mime_filter_copy (GMimeFilter *filter);
-- needs free
--- @param filter gmime.Filter
--- @return gmime.Filter
function M.filter_copy(filter)
	return ffi.gc(gmime.g_mime_filter_copy(filter), gmime.g_object_unref)
end
--
-- void g_mime_filter_filter (GMimeFilter *filter,
-- 			   char *inbuf, size_t inlen, size_t prespace,
-- 			   char **outbuf, size_t *outlen, size_t *outprespace);
--

--- @param filter gmime.Filter
--- @param inbuf any ffi allocated array of char
--- @param inlen number size of array
--- @return any, number, number
function M.filter_filter(filter, inbuf, inlen)
	local out = ffi.new("char*[1]")
	local outlen = ffi.new("size_t[1]")
	local prespace = ffi.new("size_t[1]")
	gmime.g_mime_filter_filter(filter, inbuf, inlen, out, outlen, prespace)
	return out[0], outlen[0], prespace[0]
end
-- void g_mime_filter_complete (GMimeFilter *filter,
-- 			     char *inbuf, size_t inlen, size_t prespace,
-- 			     char **outbuf, size_t *outlen, size_t *outprespace);

--- @param filter gmime.Filter
--- @param inbuf any ffi allocated array of char
--- @param inlen number size of array
--- @return any, number, number
function M.filter_complete(filter, inbuf, inlen)
	local out = ffi.new("char*[1]")
	local outlen = ffi.new("size_t[1]")
	local prespace = ffi.new("size_t[1]")
	gmime.g_mime_filter_filter(filter, inbuf, inlen, out, outlen, prespace)
	return out[0], outlen[0], prespace[0]
end
--
-- void g_mime_filter_reset (GMimeFilter *filter);
--- @param filter gmime.Filter
function M.filter_reset(filter)
	gmime.g_mime_filter_reset(filter)
end
--
--
-- void g_mime_filter_backup (GMimeFilter *filter, const char *data, size_t length);
--- @param filter gmime.Filter
--- @param data any ffi allocated array of char
--- @param size number size of array
function M.filter_backup(filter, data, size)
	gmime.g_mime_filter_backup(filter, data, size)
end

-- void g_mime_filter_set_size (GMimeFilter *filter, size_t size, gboolean keep);
--- @param size number
--- @param keep boolean
function M.filter_set_size(filter, size, keep)
	gmime.g_mime_filter_set_size(filter, size, keep)
end
--


-- GMimeFilter *g_mime_filter_best_new (GMimeFilterBestFlags flags);
--- @param flags gmime.FilterBestFlags
--- @return gmime.Filter
function M.filter_best_new(flags)
	return ffi.gc(gmime.g_mime_filter_best_new(flags), gmime.g_object_unref)
end
--
-- const char *g_mime_filter_best_charset (GMimeFilterBest *best);
--- @param best gmime.FilterBest
--- @return string
function M.filter_best_charset(best)
	return ffi.string(gmime.g_mime_filter_best_charset(best))
end

-- GMimeContentEncoding g_mime_filter_best_encoding (GMimeFilterBest *best, GMimeEncodingConstraint constraint);
--- @param best gmime.FilterBest
--- @param constraint gmime.EncodingConstraint
--- @return gmime.ContentEncoding
function M.filter_best_encoding(best, constraint)
	local con = convert.encoding_constrains(constraint)
	return gmime.g_mime_filter_best_encoding(best, con)
end
--
-- GMimeFilter *g_mime_filter_from_new (GMimeFilterFromMode mode);
--- @param mode gmime.FilterFromMode
--- @return gmime.Filter
function M.filter_from_new(mode)
	-- local from_mode = convert.frome_mode(mode)
	return gmime.g_mime_filter_from_new(mode)
end

-- GMimeFilter *g_mime_filter_gzip_new (GMimeFilterGZipMode mode, int level);
--- @param mode gmime.FilterGZipMode
--- @param level number
--- @return gmime.Filter
function M.filter_gzip_new(mode, level)
	-- local zip = convert.(constraint)
	gmime.g_mime_filter_gzip_new(mode, level)
end

-- const char *g_mime_filter_gzip_get_filename (GMimeFilterGZip *gzip);
--- @param gzip gmime.FilterGZip
--- @return string
function M.filter_gzip_get_filename(gzip)
	return ffi.string(gmime.filter_gzip_get_filename(gzip))
end

-- void g_mime_filter_gzip_set_filename (GMimeFilterGZip *gzip, const char *filename);
--- @param gzip gmime.FilterGZip
--- @param filename string
function M.filter_gzip_set_filename(gzip, filename)
	gmime.g_mime_filter_gzip_set_filename(gzip, filename)
end

-- const char *g_mime_filter_gzip_get_comment (GMimeFilterGZip *gzip);
--- @param gzip gmime.FilterGZip
--- @return string
function M.filter_gzip_get_comment(gzip)
	return ffi.string(gmime.g_mime_filter_gzip_get_comment(gzip))
end

-- void g_mime_filter_gzip_set_comment (GMimeFilterGZip *gzip, const char *comment);
--- @param gzip gmime.FilterGZip
--- @param comment string
function M.filter_gzip_set_comment(gzip, comment)
	return ffi.string(gmime.filter_gzip_set_comment(gzip, comment))
end

-- GMimeFilter *g_mime_filter_html_new (guint32 flags, guint32 colour);
--- @param flags number
--- @param color number
--- @return gmime.Filter
function M.filter_html_new(flags, color)
	return gmime.g_mime_filter_html_new(flags, color)
end

-- GMimeFilter *g_mime_filter_yenc_new (gboolean encode);
--- @param encode boolean
--- @return gmime.Filter
function M.filter_yenc_new(encode)
	return gmime.filter_yenc_new(encode)
end

-- void g_mime_filter_yenc_set_state (GMimeFilterYenc *yenc, int state);
--- @param yenc gmime.FilterYenc
--- @param state number
function M.filter_yenc_set_state(yenc, state)
	gmime.g_mime_filter_yenc_set_state(yenc, state)
end

-- void g_mime_filter_yenc_set_crc (GMimeFilterYenc *yenc, guint32 crc);
--- @param yenc gmime.FilterYenc
--- @param crc number
function M.filter_yenc_set_crc(yenc, crc)
	gmime.filter_yenc_set_crc(yenc, crc)
end


-- /*int     g_mime_filter_yenc_get_part (GMimeFilterYenc *yenc);*/
-- guint32 g_mime_filter_yenc_get_pcrc (GMimeFilterYenc *yenc);
--- @param yenc gmime.FilterYenc
--- @return number
function M.filter_yenc_get_pcrc(yenc)
	return gmime.filter_yenc_get_pcrc(yenc)
end

-- guint32 g_mime_filter_yenc_get_crc (GMimeFilterYenc *yenc);
--- @param yenc gmime.FilterYenc
--- @return number
function M.filter_yenc_get_crc(yenc)
	return gmime.g_mime_filter_yenc_get_crc(yenc)
end

--
-- size_t g_mime_ydecode_step  (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf,
-- 			     int *state, guint32 *pcrc, guint32 *crc);
-- TODO
function M.ydecode_step()
end

-- size_t g_mime_yencode_step  (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf,
-- 			     int *state, guint32 *pcrc, guint32 *crc);
-- TODO
function M.yencode_step()
end

-- size_t g_mime_yencode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf,
-- 			     int *state, guint32 *pcrc, guint32 *crc);
-- TODO
function M.yencode_close()
end

--
-- GMimeFilter *g_mime_filter_basic_new (GMimeContentEncoding encoding, gboolean encode);
--- @param encoding gmime.ContentEncoding
--- @param encode boolean
--- @return gmime.Filter
function M.filter_basic_new(encoding, encode)
	return ffi.gc(gmime.g_mime_filter_basic_new(encoding, encode), gmime.safe_unref)
end

--
-- GMimeFilter *g_mime_filter_strip_new (void);
--- @return gmime.Filter
function M.filter_strip_new()
	return ffi.gc(gmime.filter_strip_new(), gmime.g_object_unref)
end

--
-- GMimeFilter *g_mime_filter_charset_new (const char *from_charset, const char *to_charset);
--- @param from string
--- @param to string
--- @return gmime.Filter
function M.filter_charset_new(from, to)
	return ffi.gc(gmime.g_mime_filter_charset_new(from, to), gmime.g_object_unref)
end

--
-- GMimeFilter *g_mime_filter_openpgp_new (void);
--- @return gmime.Filter
function M.filter_openpgp_new()
	return ffi.gc(gmime.g_mime_filter_openpgp_new(), gmime.safe_unref)
end

--
-- GMimeOpenPGPData g_mime_filter_openpgp_get_data_type (GMimeFilterOpenPGP *openpgp);
--- @param openpgp gmime.FilterOpenPGP
--- @return gmime.OpenPGPData
function M.filter_openpgp_get_data_type(openpgp)
	return gmime.g_mime_filter_openpgp_get_data_type(openpgp)
end

-- gint64 g_mime_filter_openpgp_get_begin_offset (GMimeFilterOpenPGP *openpgp);
--- @param openpgp gmime.FilterOpenPGP
--- XXX
function M.filter_openpgp_get_begin_offset(openpgp)
	return gmime.filter_openpgp_get_begin_offset(openpgp)
end

-- gint64 g_mime_filter_openpgp_get_end_offset (GMimeFilterOpenPGP *openpgp);
--- @param openpgp gmime.FilterOpenPGP
--- XXX
function M.filter_openpgp_get_end_offset(openpgp)
	return gmime.g_mime_filter_openpgp_get_end_offset(openpgp)
end

--
-- GMimeFilter *g_mime_filter_windows_new (const char *claimed_charset);
--- @param claimed string
--- @return gmime.Filter
function M.filter_windows_new(claimed)
	return ffi.gc(gmime.g_mime_filter_windows_new(claimed), gmime.g_object_unref)
end

-- gboolean g_mime_filter_windows_is_windows_charset (GMimeFilterWindows *filter);
--- @param filter gmime.FilterWindows
--- @return boolean
function M.filter_windows_is_windows_charset(filter)
	return gmime.filter_windows_is_windows_charset(filter)
end

-- const char *g_mime_filter_windows_real_charset (GMimeFilterWindows *filter);
--- @param filter gmime.FilterWindows
--- @return string
function M.filter_windows_real_charset(filter)
	return ffi.string(gmime.g_mime_filter_windows_real_charset(filter))
end

-- GMimeFilter *g_mime_filter_checksum_new (GChecksumType type);
--- @param type gmime.ChecksumType
--- @return gmime.Filter
function M.filter_checksum_new(type)
	return gmime.g_mime_filter_checksum_new(type)
end

--
-- size_t g_mime_filter_checksum_get_digest (GMimeFilterChecksum *checksum, unsigned char *digest, size_t len);
--- @param checksum gmime.FilterChecksum
--- @param digest string
--- @param len number
function M.filter_checksum_get_digest(checksum, digest, len)
	return gmime.filter_checksum_get_digest(checksum, digest, len)
end

-- gchar *g_mime_filter_checksum_get_string (GMimeFilterChecksum *checksum);
--- @param checksum gmime.FilterChecksum
--- @return string
function M.filter_checksum_get_string(checksum)
	local mem = gmime.g_mime_filter_checksum_get_string(checksum)
	return convert.strdup(mem)
end

--
-- GMimeFilter *g_mime_filter_dos2unix_new (gboolean ensure_newline);
--- @param newline boolean
--- @return gmime.Filter
function M.filter_dos2unix_new(newline)
	return ffi.gc(gmime.g_mime_filter_dos2unix_new(newline), gmime.g_object_unref)
end

--
-- GMimeFilter *g_mime_filter_unix2dos_new (gboolean ensure_newline);
--- @param newline boolean
--- @return gmime.Filter
function M.filter_unix2dos_new(newline)
	return ffi.gc(gmime.g_mime_filter_unix2dos_new(newline), gmime.g_object_unref)
end

--
-- GMimeFilter *g_mime_filter_enriched_new (guint32 flags);
--- @param flags number
--- @return gmime.Filter
function M.filter_enriched_new(flags)
	return ffi.gc(gmime.g_mime_filter_enriched_new(flags), gmime.g_object_unref)
end

--
-- GMimeFilter *g_mime_filter_smtp_data_new (void);
--- @return gmime.Filter
function M.filter_smtp_data_new()
	return ffi.gc(gmime.g_mime_filter_smtp_data_new(), gmime.g_object_unref)
end

-- GMimeFilter *g_mime_filter_reply_new (gboolean encode);
--- @param encode boolean
--- @return gmime.Filter
function M.filter_reply_new(encode)
	return ffi.gc(gmime.g_mime_filter_reply_new(encode), gmime.g_object_unref)
end

return M
