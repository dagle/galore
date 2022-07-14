--- @diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

--- @param filter gmime.Filter
--- @return gmime.Filter
function M.filter_copy(filter)
	return ffi.gc(gmime.g_mime_filter_copy(filter), gmime.g_object_unref)
end

--- @param filter gmime.Filter
--- @param inbuf any
--- @param prespace integer
--- @return any, number, number
--- XXX This doesn't make sense.
--- Maybe not do this in lua or export a c-style-api
function M.filter_filter(filter, inbuf, prespace)
	local inlen = #inbuf
	local out = ffi.new("char*[1]")
	local outlen = ffi.new("size_t[1]")
	local outspace = ffi.new("size_t[1]")
	gmime.g_mime_filter_filter(filter, inbuf, inlen, prespace, out, outlen, outspace)
	return out[0], outlen[0], outspace[0]
end

--- @param filter gmime.Filter
--- @param inbuf any ffi allocated array of char
--- @param inlen number size of array
--- @return any, number, number
--- XXX This doesn't make sense.
function M.filter_complete(filter, inbuf, inlen)
	local out = ffi.new("char*[1]")
	local outlen = ffi.new("size_t[1]")
	local prespace = ffi.new("size_t[1]")
	gmime.g_mime_filter_filter(filter, inbuf, inlen, out, outlen, prespace)
	return out[0], outlen[0], prespace[0]
end

--- @param filter gmime.Filter
function M.filter_reset(filter)
	gmime.g_mime_filter_reset(filter)
end

--- @param filter gmime.Filter
--- @param data any ffi allocated array of char
function M.filter_backup(filter, data)
	gmime.g_mime_filter_backup(filter, data, #data)
end

--- @param size number
--- @param keep boolean
function M.filter_set_size(filter, size, keep)
	gmime.g_mime_filter_set_size(filter, size, keep)
end

--- @param flags gmime.FilterBestFlags
--- @return gmime.Filter
function M.filter_best_new(flags)
	return ffi.gc(gmime.g_mime_filter_best_new(flags), gmime.g_object_unref)
end

--- @param best string ("charset" | "encoding")
--- @return string
function M.filter_best_charset(best)
	local fbest = convert.best_flag(best)
	return ffi.string(gmime.g_mime_filter_best_charset(fbest))
end

--- @param best gmime.FilterBest
--- @param constraint gmime.EncodingConstraint
--- @return gmime.ContentEncoding
function M.filter_best_encoding(best, constraint)
	local con = convert.encoding_constrains(constraint)
	return gmime.g_mime_filter_best_encoding(best, con)
end

--- @param mode string ("default" | "escape" | "armor")
--- @return gmime.Filter
function M.filter_from_new(mode)
	local fmode = convert.to_filter_from(mode)
	return gmime.g_mime_filter_from_new(fmode)
end

--- @param mode string ("zip" | "unzip")
--- @param level number
--- @return gmime.Filter
function M.filter_gzip_new(mode, level)
	local zmode = convert.to_gzip_mode(mode)
	gmime.g_mime_filter_gzip_new(zmode, level)
end

--- @param gzip gmime.FilterGZip
--- @return string
function M.filter_gzip_get_filename(gzip)
	return ffi.string(gmime.filter_gzip_get_filename(gzip))
end

--- @param gzip gmime.FilterGZip
--- @param filename string
function M.filter_gzip_set_filename(gzip, filename)
	gmime.g_mime_filter_gzip_set_filename(gzip, filename)
end

--- @param gzip gmime.FilterGZip
--- @return string
function M.filter_gzip_get_comment(gzip)
	return ffi.string(gmime.g_mime_filter_gzip_get_comment(gzip))
end

--- @param gzip gmime.FilterGZip
--- @param comment string
function M.filter_gzip_set_comment(gzip, comment)
	return ffi.string(gmime.filter_gzip_set_comment(gzip, comment))
end

--- @param flags number
--- @param color number
--- @return gmime.Filter
function M.filter_html_new(flags, color)
	return gmime.g_mime_filter_html_new(flags, color)
end

--- @param encode boolean
--- @return gmime.Filter
function M.filter_yenc_new(encode)
	return gmime.filter_yenc_new(encode)
end

--- @param yenc gmime.FilterYenc
--- @param state number
function M.filter_yenc_set_state(yenc, state)
	gmime.g_mime_filter_yenc_set_state(yenc, state)
end

--- @param yenc gmime.FilterYenc
--- @param crc number
function M.filter_yenc_set_crc(yenc, crc)
	gmime.filter_yenc_set_crc(yenc, crc)
end

--- Doesn't work upstream atm
-- /*int     g_mime_filter_yenc_get_part (GMimeFilterYenc *yenc);*/

--- @param yenc gmime.FilterYenc
--- @return number
function M.filter_yenc_get_pcrc(yenc)
	return gmime.filter_yenc_get_pcrc(yenc)
end

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

--- @param encoding ("default" | "7bit" | "8bit" | "binary" | "base64" | "quotedprintable" | "uuencode")
--- @param encode boolean
--- @return gmime.Filter
function M.filter_basic_new(encoding, encode)
	local eencoding = convert.to_encoding(encoding)
	return ffi.gc(gmime.g_mime_filter_basic_new(eencoding, encode), gmime.g_object_unref)
end

--- @return gmime.Filter
function M.filter_strip_new()
	return ffi.gc(gmime.filter_strip_new(), gmime.g_object_unref)
end

--- @param from string
--- @param to string
--- @return gmime.Filter
function M.filter_charset_new(from, to)
	return ffi.gc(gmime.g_mime_filter_charset_new(from, to), gmime.g_object_unref)
end

--- @return gmime.Filter
function M.filter_openpgp_new()
	return ffi.gc(gmime.g_mime_filter_openpgp_new(), gmime.g_object_unref)
end

--- @param openpgp gmime.FilterOpenPGP
--- @return gmime.OpenPGPData
function M.filter_openpgp_get_data_type(openpgp)
	return gmime.g_mime_filter_openpgp_get_data_type(openpgp)
end

--- @param openpgp gmime.FilterOpenPGP
function M.filter_openpgp_get_begin_offset(openpgp)
	return gmime.filter_openpgp_get_begin_offset(openpgp)
end

--- @param openpgp gmime.FilterOpenPGP
function M.filter_openpgp_get_end_offset(openpgp)
	return gmime.g_mime_filter_openpgp_get_end_offset(openpgp)
end

--- @param claimed string
--- @return gmime.Filter
function M.filter_windows_new(claimed)
	return ffi.gc(gmime.g_mime_filter_windows_new(claimed), gmime.g_object_unref)
end

--- @param filter gmime.FilterWindows
--- @return boolean
function M.filter_windows_is_windows_charset(filter)
	return gmime.filter_windows_is_windows_charset(filter)
end

--- @param filter gmime.FilterWindows
--- @return string
function M.filter_windows_real_charset(filter)
	return ffi.string(gmime.g_mime_filter_windows_real_charset(filter))
end

--- @param type gmime.ChecksumType
--- @return gmime.Filter
function M.filter_checksum_new(type)
	local check = convert.to_checksum_type(type)
	return gmime.g_mime_filter_checksum_new(check)
end

--- @param checksum gmime.FilterChecksum
function M.filter_checksum_get_digest(checksum, len)
	local digest = ffi.new("unsigned char[?]", len)
	local ret = gmime.filter_checksum_get_digest(checksum, digest, len)
	return ffi.string(digest)
end

--- @param checksum gmime.FilterChecksum
--- @return string
function M.filter_checksum_get_string(checksum)
	local mem = gmime.g_mime_filter_checksum_get_string(checksum)
	return convert.strdup(mem)
end

--- @param newline boolean
--- @return gmime.Filter
function M.filter_dos2unix_new(newline)
	return ffi.gc(gmime.g_mime_filter_dos2unix_new(newline), gmime.g_object_unref)
end

--- @param newline boolean
--- @return gmime.Filter
function M.filter_unix2dos_new(newline)
	return ffi.gc(gmime.g_mime_filter_unix2dos_new(newline), gmime.g_object_unref)
end

--
--- @param flags number
--- @return gmime.Filter
function M.filter_enriched_new(flags)
	return ffi.gc(gmime.g_mime_filter_enriched_new(flags), gmime.g_object_unref)
end

--- @return gmime.Filter
function M.filter_smtp_data_new()
	return ffi.gc(gmime.g_mime_filter_smtp_data_new(), gmime.g_object_unref)
end

--- @param encode boolean
--- @return gmime.Filter
function M.filter_reply_new(encode)
	return ffi.gc(gmime.g_mime_filter_reply_new(encode), gmime.g_object_unref)
end

return M
