---@diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local safe = require("galore.gmime.funcs")
local ffi = require("ffi")

local M = {}

--- @param str string
--- @return gmime.ContentEncoding
function M.content_encoding_from_string(str)
	return gmime.g_mime_content_encoding_from_string(str)
end

--- @param encoding gmime.ContentEncoding
--- @return string
function M.content_encoding_to_string(encoding)
	return ffi.string(gmime.g_mime_content_encoding_to_string(encoding))
end

--- @return gmime.EncodingState
function M.encoding_new()
	return ffi.new("GMimeEncoding[1]")
end

--- @param state gmime.EncodingState
--- @param encoding gmime.ContentEncoding
function M.encoding_init_encode(state, encoding)
	gmime.g_mime_encoding_init_encode(state, encoding)
end

--- @param state gmime.EncodingState
--- @param encoding gmime.ContentEncoding
function M.encoding_init_decode(state, encoding)
	gmime.g_mime_encoding_init_decode(state, encoding)
end

--- @param state gmime.EncodingState
function M.encoding_reset(state)
	gmime.g_mime_encoding_reset(state)
end

--- @param state gmime.EncodingState
--- @param len integer
--- @return integer
function M.encoding_outlen(state, len)
	return gmime.g_mime_encoding_outlen(state, len)
end

--- @param state gmime.EncodingState
function M.encoding_step(state, inbuf, inlen)
	local len = gmime.g_mime_encoding_outlen(state, inlen)
	local outbuf = ffi.new("char[?]", len)
	local ret = gmime.g_mime_encoding_step(state, inbuf, inlen, outbuf)
	return ffi.string(outbuf, ret), ret
end

--- @param state gmime.EncodingState
--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_flush(state, inbuf, inlen, outbuf)
	return gmime.g_mime_encoding_flush(state, inbuf, inlen, outbuf)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_base64_decode_step(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_base64_decode_step(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_base64_encode_step(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_base64_encode_step(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_base64_encode_close(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_base64_encode_close(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_uudecode_step(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_uudecode_step(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_uuencode_step(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_uuencode_step(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_uuencode_close(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_uuencode_close(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_quoted_decode_step(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_quoted_decode_step(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_quoted_encode_step(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_quoted_encode_step(inbuf, inlen, outbuf, state, save)
end

--- @param inbuf string
--- @param inlen number
--- @param outbuf any
--- @param state any
--- @param save any
--- outbuf is a char*, state is a int* and save is int *
--- create them using ffi.new(), outbuf needs to be able to hold inbuf
function M.encoding_quoted_encode_close(inbuf, inlen, outbuf, state, save)
	return gmime.g_mime_encoding_quoted_encode_close(inbuf, inlen, outbuf, state, save)
end

--- @param to string
--- @param from string
--- @return iconv
function M.iconv_open(to, from)
	return gmime.g_mime_iconv_open(to, from)
end

--- @param cd iconv
--- @return number
function M.iconv_close(cd)
	return gmime.g_mime_iconv_close(cd)
end

function M.charset_map_init()
	gmime.g_mime_charset_map_init()
end

function M.charset_map_shutdown()
	gmime.g_mime_charset_map_shutdown()
end

--- @return string
function M.locale_charset()
	return ffi.string(gmime.g_mime_locale_charset())
end

--- @return string
function M.locale_language()
	return ffi.string(gmime.g_mime_locale_language())
end

--- @param charset string
--- @return string
function M.charset_language(charset)
	return ffi.string(gmime.g_mime_charset_language(charset))
end

--- @param charset string
--- @return string
function M.charset_canon_name(charset)
	return ffi.string(gmime.g_mime_charset_canon_name(charset))
end

--- @param charset string
--- @return string
function M.charset_iconv_name(charset)
	return ffi.string(gmime.g_mime_charset_iconv_name(charset))
end

--- @param isocharset string
--- @return string
function M.charset_iso_to_windows(isocharset)
	return ffi.string(gmime.g_mime_charset_iso_to_windows(isocharset))
end

--- @return gmime.Charset
function M.charset_init()
	local charset = ffi.new("GMimeCharset[1]")
	gmime.g_mime_charset_init(charset)
	return charset
end

function M.charset_step(charset, str)
	gmime.g_mime_charset_step(charset, str, #str)
end

function M.charset_best_name(charset)
	return ffi.string(gmime.g_mime_charset_best_name(charset))
end

function M.charset_best(str)
	return ffi.string(gmime.g_mime_charset_best(str, #str))
end

--- @param mask gmime.Charset
--- @param charset string
--- @param text string
--- @return boolean
function M.charset_can_encode(mask, charset, text)
	return gmime.g_mime_charset_can_encode(mask, charset, text, #text)
end

--- @param cd gmime.iconv
--- @param str string
function M.iconv_strdup(cd, str)
	local mem = gmime.g_mime_iconv_strdup(cd, str)
	return safe.strdup(mem)
end

--- @param cd gmime.iconv
--- @param str string
--- @param size number
function M.iconv_strndup(cd, str, size)
	local mem = gmime.g_mime_iconv_strndup(cd, str, size)
	return safe.strdup(mem)
end

--- @param str string
--- @return string
function M.iconv_locale_to_utf8(str)
	local mem = gmime.g_mime_iconv_locale_to_utf8(str)
	return safe.strdup(mem)
end

--- @param str string
--- @param length number
--- @return string
function M.iconv_locale_to_utf8_length(str, length)
	local mem = gmime.g_mime_iconv_locale_to_utf8_length(str, length)
	return safe.strdup(mem)
end

--- @param str string
--- @return string
function M.iconv_utf8_to_locale(str)
	local mem = gmime.g_mime_iconv_utf8_to_locale(str)
	return safe.strdup(mem)
end

--- @param str string
--- @param len number
--- @return string
function M.iconv_utf8_to_locale_length(str, len)
	local mem = gmime.g_mime_iconv_utf8_to_locale_length(str, len)
	return safe.strdup(mem)
end

--- @return string
function M.make_maildir_id()
	local mem = gmime.make_maildir_id();
	return safe.strdup(mem)
end

return M
