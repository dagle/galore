local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

-- GMimeFilter *g_mime_filter_copy (GMimeFilter *filter);
-- needs free
--- @param filter gmime.Filter
--- @return gmime.Filter
function M.filter_copy(filter)
	return gmime.g_mime_filter_copy(filter)
end
--
-- void g_mime_filter_filter (GMimeFilter *filter,
-- 			   char *inbuf, size_t inlen, size_t prespace,
-- 			   char **outbuf, size_t *outlen, size_t *outprespace);
--

-- TODO, we don't want to define a buf in lua
function M.filter_filter(filter)
end
-- void g_mime_filter_complete (GMimeFilter *filter,
-- 			     char *inbuf, size_t inlen, size_t prespace,
-- 			     char **outbuf, size_t *outlen, size_t *outprespace);

-- TODO, we don't want to define a buf in lua
function M.filter_complete(filter)
end
--
-- void g_mime_filter_reset (GMimeFilter *filter);
function M.filter_reset(filter)
	gmime.g_mime_filter_reset(filter)
end
--
--
-- void g_mime_filter_backup (GMimeFilter *filter, const char *data, size_t length);
-- TODO, we don't want to define a buf in lua
function M.filter_backup(filter)
end
--
-- void g_mime_filter_set_size (GMimeFilter *filter, size_t size, gboolean keep);
function M.filter_set_size(filter, size, keep)
	gmime.g_mime_filter_set_size(filter, size, keep)
end
--


-- GMimeFilter *g_mime_filter_best_new (GMimeFilterBestFlags flags);
function M.filter_best_new(flags)
	return gmime.g_mime_filter_best_new(flags)
end
--
-- const char *g_mime_filter_best_charset (GMimeFilterBest *best);
function M.filter_best_charset(best)
	return ffi.string(gmime.g_mime_filter_best_charset())
end
--

-- GMimeContentEncoding g_mime_filter_best_encoding (GMimeFilterBest *best, GMimeEncodingConstraint constraint);
function M.filter_best_encoding(best, constraint)
	local con = convert.encoding_constrains(constraint)
	return gmime.g_mime_filter_best_encoding(best, con)
end
--
-- GMimeFilter *g_mime_filter_from_new (GMimeFilterFromMode mode);
function M.filter_from_new(mode)
	local from_mode = convert.frome_mode(mode)
	return gmime.g_mime_filter_from_new(from_mode)
end
--
-- GMimeFilter *g_mime_filter_gzip_new (GMimeFilterGZipMode mode, int level);
function M.filter_gzip_new(mode, level)
	local zip = convert.(constraint)
	gmime.g_mime_filter_gzip_new(zip, level)
end
--

-- const char *g_mime_filter_gzip_get_filename (GMimeFilterGZip *gzip);
function M.filter_gzip_get_filename(gzip)
	return ffi.string(gime.filter_gzip_get_filename)
end

-- void g_mime_filter_gzip_set_filename (GMimeFilterGZip *gzip, const char *filename);
function M.filter_gzip_set_filename(gzip, filename)
	gmime.g_mime_filter_gzip_set_filename(gzip, filename)
end

--
-- const char *g_mime_filter_gzip_get_comment (GMimeFilterGZip *gzip);
function M.filter_gzip_get_comment(gzip)
	return ffi.string(gmime.g_mime_filter_gzip_get_comment(gzip))
end
-- void g_mime_filter_gzip_set_comment (GMimeFilterGZip *gzip, const char *comment);
function M.filter_gzip_set_comment(gzip, comment)
	return ffi.string(gmime.filter_gzip_set_comment(gzip, comment))
end
--
-- GMimeFilter *g_mime_filter_html_new (guint32 flags, guint32 colour);
function M.filter_html_new(flags, color)
	return gmime.g_mime_filter_html_new(flags, color)
end
--
-- GMimeFilter *g_mime_filter_yenc_new (gboolean encode);
function M.filter_yenc_new(encode)
	return gmime.filter_yenc_new(encode)
end
--
-- void g_mime_filter_yenc_set_state (GMimeFilterYenc *yenc, int state);
function M.filter_yenc_set_state(yenc, state)
	gmime.g_mime_filter_yenc_set_state(yenc, state)
end
-- void g_mime_filter_yenc_set_crc (GMimeFilterYenc *yenc, guint32 crc);
function M.filter_yenc_set_crc(yenc, crc)
	filter_yenc_set_crc(yenc, crc)
end
--
-- /*int     g_mime_filter_yenc_get_part (GMimeFilterYenc *yenc);*/
-- guint32 g_mime_filter_yenc_get_pcrc (GMimeFilterYenc *yenc);
function M.filter_yenc_get_pcrc(yenc)
	return gmime.filter_yenc_get_pcrc(yenc)
end

-- guint32 g_mime_filter_yenc_get_crc (GMimeFilterYenc *yenc);
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
function M.filter_basic_new(encoding, encode)
	
end

--
-- GMimeFilter *g_mime_filter_strip_new (void);
function M.filter_strip_new()
	
end

--
-- GMimeFilter *g_mime_filter_charset_new (const char *from_charset, const char *to_charset);
function M.filter_charset_new(from, to)
	
end

--
-- GMimeFilter *g_mime_filter_openpgp_new (void);
function M.filter_openpgp_new()
	return gmime.g_mime_filter_openpgp_new()
end

--
-- GMimeOpenPGPData g_mime_filter_openpgp_get_data_type (GMimeFilterOpenPGP *openpgp);
function M.filter_openpgp_get_data_type(openpgp)
	return gmime.g_mime_filter_openpgp_get_data_type(openpgp)
end

-- gint64 g_mime_filter_openpgp_get_begin_offset (GMimeFilterOpenPGP *openpgp);
function M.filter_openpgp_get_begin_offset(openpgp)
	return tonumber(gmime.filter_openpgp_get_begin_offset(openpgp))
end

-- gint64 g_mime_filter_openpgp_get_end_offset (GMimeFilterOpenPGP *openpgp);
function M.filter_openpgp_get_end_offset(openpgp)
	return tonumber(gmime.g_mime_filter_openpgp_get_end_offset(openpgp))
end

--
-- GMimeFilter *g_mime_filter_windows_new (const char *claimed_charset);
function M.filter_windows_new(claimed)
	return gmime.g_mime_filter_windows_new(clain)
end

--
--
-- gboolean g_mime_filter_windows_is_windows_charset (GMimeFilterWindows *filter);
function M.filter_windows_is_windows_charset(filter)
	return gmime.filter_windows_is_windows_charset(filter)
end

--
-- const char *g_mime_filter_windows_real_charset (GMimeFilterWindows *filter);
function M.filter_windows_real_charset(filter)
	return ffi.string(g_mime_filter_windows_real_charset(filter))
end

--
-- GMimeFilter *g_mime_filter_checksum_new (GChecksumType type);
function M.filter_checksum_new(type)
	return gmime.g_mime_filter_checksum_new(type)
end

--
-- size_t g_mime_filter_checksum_get_digest (GMimeFilterChecksum *checksum, unsigned char *digest, size_t len);
function M.filter_checksum_get_digest(checksum, digest)
	return tonumber(gmime.filter_checksum_get_digest(checksum, digest, #digest))
end

--
-- gchar *g_mime_filter_checksum_get_string (GMimeFilterChecksum *checksum);
function M.filter_checksum_get_string(checksum)
	return ffi.string(g_mime_filter_checksum_get_string(checksum))
end

--
-- GMimeFilter *g_mime_filter_dos2unix_new (gboolean ensure_newline);
function M.filter_dos2unix_new(newline)
	return gmime.g_mime_filter_dos2unix_new(newline)
end

--
-- GMimeFilter *g_mime_filter_unix2dos_new (gboolean ensure_newline);
function M.filter_unix2dos_new(newline)
	return gmime.g_mime_filter_unix2dos_new(newline)
end

--
-- GMimeFilter *g_mime_filter_enriched_new (guint32 flags);
function M.filter_enriched_new(flags)
	return gmime.g_mime_filter_enriched_new(flags)
end

--
-- GMimeFilter *g_mime_filter_smtp_data_new (void);
function M.filter_smtp_data_new(flags)
	return gmime.g_mime_filter_smtp_data_new()
end

-- GMimeFilter *g_mime_filter_reply_new (gboolean encode);
function M.filter_reply_new(encode)
	return gmime.g_mime_filter_reply_new()
end

return M
