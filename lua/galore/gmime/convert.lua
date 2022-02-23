local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}

function M.strdup(mem)
	local str = ffi.string(mem)
	gmime.free(mem)
	return str
end

function M.encoding_to_string(encoding)
	if encoding == gmime.GMIME_CONTENT_ENCODING_DEFAULT then
		return "default"
	elseif encoding == gmime.GMIME_CONTENT_ENCODING_7BIT then
		return "7bit"
	elseif encoding == gmime.GMIME_CONTENT_ENCODING_8BIT then
		return "8bit"
	elseif encoding == gmime.GMIME_CONTENT_ENCODING_BINARY then
		return "binary"
	elseif encoding == gmime.GMIME_CONTENT_ENCODING_BASE64 then
		return "base64"
	elseif encoding == gmime.GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE then
		return "quotedprintable"
	elseif encoding == gmime.GMIME_CONTENT_ENCODING_UUENCODE then
		return "uuencode"
	end
end

function M.string_to_encoding(mode)
	if mode == "default" then
		return gmime.GMIME_CONTENT_ENCODING_DEFAULT
	elseif mode == "7bit" then
		return gmime.GMIME_CONTENT_ENCODING_7BIT
	elseif mode == "8bit" then
		return gmime.GMIME_CONTENT_ENCODING_8BIT
	elseif mode == "binary" then
		return gmime.GMIME_CONTENT_ENCODING_BINARY
	elseif mode == "base64" then
		return gmime.GMIME_CONTENT_ENCODING_BASE64
	elseif mode == "quotedprintable" then
		return gmime.GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE
	elseif mode == "uuencode" then
		return gmime.GMIME_CONTENT_ENCODING_UUENCODE
	end
end

function M.encoding_constrains(constraint)
	if constraint == "7bit" then
		return gmime.GMIME_ENCODING_CONSTRAINT_7BIT
	elseif constraint == "8bit" then
		return gmime.GMIME_ENCODING_CONSTRAINT_8BIT
	elseif constraint == "binary" then
		return gmime.GMIME_ENCODING_CONSTRAINT_BINARY
	end
end

function M.address_type(type)
	if type == "sender" then
		return gmime.GMIME_ADDRESS_TYPE_SENDER
	elseif type == "from" then
		return gmime.GMIME_ADDRESS_TYPE_FROM
	elseif type == "reply_to" then
		return gmime.GMIME_ADDRESS_TYPE_REPLY_TO
	elseif type == "to" then
		return gmime.GMIME_ADDRESS_TYPE_TO
	elseif type == "cc" then
		return gmime.GMIME_ADDRESS_TYPE_CC
	elseif type == "bcc" then
		return gmime.GMIME_ADDRESS_TYPE_BCC
	end
end

function M.encryption_flags(flags)
	local eflags
	if flags == "none" then
		eflags = gmime.GMIME_ENCRYPT_NONE
	elseif flags == "always_trust" then
		eflags = gmime.GMIME_ENCRYPT_ALWAYS_TRUST
	elseif flags == "no_compress" then
		eflags = gmime.GMIME_ENCRYPT_NO_COMPRESS
	elseif flags == "symmetric" then
		eflags = gmime.GMIME_ENCRYPT_SYMMETRIC
	elseif flags == "throw_keyids" then
		eflags = gmime.GMIME_ENCRYPT_THROW_KEYIDS
	end
	return eflags
end

--- XXX being able to combine!
--- Take a table or a string.
--- Table does bit-or on the flags
function M.decrytion_flag(flags)
	if flags == "none" then
		return gmime.GMIME_DECRYPT_NONE
	elseif flags == "session" then
		return gmime.GMIME_DECRYPT_EXPORT_SESSION_KEY
	elseif flags == "verify" then
		return gmime.GMIME_DECRYPT_NO_VERIFY
	elseif flags == "keyserver" then
		return gmime.GMIME_DECRYPT_ENABLE_KEYSERVER_LOOKUPS
	elseif flags == "online" then
		return gmime.GMIME_DECRYPT_ENABLE_ONLINE_CERTIFICATE_CHECKS
	end
end

function M.frome_mode(mode)
	if mode == "default" then
		return gmime.GMIME_FILTER_FROM_MODE_DEFAULT
	elseif mode == "escape" then
		return gmime.GMIME_FILTER_FROM_MODE_ESCAPE
	elseif mode == "armor" then
		return gmime.GMIME_FILTER_FROM_MODE_ARMOR
	end
end

-- typedef enum {
-- 	GMIME_DIGEST_ALGO_DEFAULT       = 0,
-- 	GMIME_DIGEST_ALGO_MD5           = 1,
-- 	GMIME_DIGEST_ALGO_SHA1          = 2,
-- 	GMIME_DIGEST_ALGO_RIPEMD160     = 3,
-- 	GMIME_DIGEST_ALGO_MD2           = 5,
-- 	GMIME_DIGEST_ALGO_TIGER192      = 6,
-- 	GMIME_DIGEST_ALGO_HAVAL5160     = 7,
-- 	GMIME_DIGEST_ALGO_SHA256        = 8,
-- 	GMIME_DIGEST_ALGO_SHA384        = 9,
-- 	GMIME_DIGEST_ALGO_SHA512        = 10,
-- 	GMIME_DIGEST_ALGO_SHA224        = 11,
-- 	GMIME_DIGEST_ALGO_MD4           = 301,
-- 	GMIME_DIGEST_ALGO_CRC32         = 302,
-- 	GMIME_DIGEST_ALGO_CRC32_RFC1510 = 303,
-- 	GMIME_DIGEST_ALGO_CRC32_RFC2440 = 304
-- } GMimeDigestAlgo;

-- typedef enum {
-- 	GMIME_PUBKEY_ALGO_DEFAULT  = 0,
-- 	GMIME_PUBKEY_ALGO_RSA      = 1,
-- 	GMIME_PUBKEY_ALGO_RSA_E    = 2,
-- 	GMIME_PUBKEY_ALGO_RSA_S    = 3,
-- 	GMIME_PUBKEY_ALGO_ELG_E    = 16,
-- 	GMIME_PUBKEY_ALGO_DSA      = 17,
-- 	GMIME_PUBKEY_ALGO_ECC      = 18,
-- 	GMIME_PUBKEY_ALGO_ELG      = 20,
-- 	GMIME_PUBKEY_ALGO_ECDSA    = 301,
-- 	GMIME_PUBKEY_ALGO_ECDH     = 302,
-- 	GMIME_PUBKEY_ALGO_EDDSA    = 303
-- } GMimePubKeyAlgo;
--
function M.digestAlgo(algo)

end

return M
