--- @diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local bit = require("bit")

local M = {}

local function bit_mask(list, func)
	return bit.bor(unpack(vim.tbl_map(func, list)))
end

--- @param atype string
--- @return integer
function M.to_address_type(atype)
	if type(atype) == "string" then
		atype = atype:lower()
		if atype == "sender" then
			return gmime.GMIME_ADDRESS_TYPE_SENDER
		elseif atype == "from" then
			return gmime.GMIME_ADDRESS_TYPE_FROM
		elseif atype == "reply_to" then
			return gmime.GMIME_ADDRESS_TYPE_REPLY_TO
		elseif atype == "to" then
			return gmime.GMIME_ADDRESS_TYPE_TO
		elseif atype == "cc" then
			return gmime.GMIME_ADDRESS_TYPE_CC
		elseif atype == "bcc" then
			return gmime.GMIME_ADDRESS_TYPE_BCC
		end
	end
end

--- @param ctype string
--- @return integer
function M.to_checksum_type(ctype)
	if type(ctype) == "string" then
		ctype = ctype:lower()
		if ctype == "md5" then
			return gmime.G_CHECKSUM_MD5
		elseif ctype == "sha1" then
			return gmime.G_CHECKSUM_SHA1
		elseif ctype == "sha256" then
			return gmime.G_CHECKSUM_SHA256
		elseif ctype == "sha512" then
			return gmime.G_CHECKSUM_SHA512
		elseif ctype == "sha384" then
			return gmime.G_CHECKSUM_SHA384
		end
	-- elseif type(ctype) == "table" then
	-- 	return bit_mask(ctype, M.to_checksum_type)
	else
		return ctype
	end
end

--- @param trust string
--- @return integer
function M.to_trust(trust)
	if type(trust) == "string" then
		trust = trust:lower()
		if trust == "unknown" then
			return gmime.GMIME_TRUST_UNKNOWN
		elseif trust == "undefined" then
			return gmime.GMIME_TRUST_UNDEFINED
		elseif trust == "never" then
			return gmime.GMIME_TRUST_NEVER
		elseif trust == "marginal" then
			return gmime.GMIME_TRUST_MARGINAL
		elseif trust == "full" then
			return gmime.GMIME_TRUST_FULL
		elseif trust == "ultimate" then
			return gmime.GMIME_TRUST_ULTIMATE
		end
	-- elseif type(trust) == "table" then
	-- 	return bit_mask(trust, M.to_trust)
	else
		return trust
	end
end

--- @param val string
--- @return integer
function M.to_validaty(val)
	if type(val) == "string" then
		val = val:lower()
		if val == "unknown" then
			return gmime.GMIME_VALIDITY_UNKNOWN
		elseif val == "undefined" then
			return gmime.GMIME_VALIDITY_UNDEFINED
		elseif val == "never" then
			return gmime.GMIME_VALIDITY_NEVER
		elseif val == "marginal" then
			return gmime.GMIME_VALIDITY_MARGINAL
		elseif val == "full" then
			return gmime.GMIME_VALIDITY_FULL
		elseif val == "ultimate" then
			return gmime.GMIME_VALIDITY_ULTIMATE
		end
	-- elseif type(val) == "table" then
	-- 	return bit_mask(val, M.to_validaty)
	else
		return val
	end
end

--- @param mode string
--- @return integer
function M.to_encoding(mode)
	if type(mode) == "string" then
	mode = mode:lower()
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
	-- elseif type(mode) == "table" then
	-- 	return bit_mask(mode, M.to_encoding)
	else
		return mode
	end
end

--- @param constraint string
--- @return integer
function M.to_constraints(constraint)
	if type(constraint) == "string" then
		constraint = constraint:lower()
		if constraint == "7bit" then
			return gmime.GMIME_ENCODING_CONSTRAINT_7BIT
		elseif constraint == "8bit" then
			return gmime.GMIME_ENCODING_CONSTRAINT_8BIT
		elseif constraint == "binary" then
			return gmime.GMIME_ENCODING_CONSTRAINT_BINARY
		end
	-- elseif type(constraint) == "table" then
	-- 	return bit_mask(constraint, M.to_constraints)
	else
		return constraint
	end
end

--- @param algo string
--- @return integer
function M.to_pub_algo(algo)
	if type(algo) == "string" then
	algo = algo:lower()
	if algo == "default" then
		return gmime.GMIME_PUBKEY_ALGO_DEFAULT
	elseif algo == "rsa" then
		return gmime.GMIME_PUBKEY_ALGO_RSA
	elseif algo == "rsae" then
		return gmime.GMIME_PUBKEY_ALGO_RSA_E
	elseif algo == "rsas" then
		return gmime.GMIME_PUBKEY_ALGO_RSA_S
	elseif algo == "elge" then
		return gmime.GMIME_PUBKEY_ALGO_ELG_E
	elseif algo == "dsa" then
		return gmime.GMIME_PUBKEY_ALGO_DSA
	elseif algo == "ecc" then
		return gmime.GMIME_PUBKEY_ALGO_ECC
	elseif algo == "elg" then
		return gmime.GMIME_PUBKEY_ALGO_ELG
	elseif algo == "ecdsa" then
		return gmime.GMIME_PUBKEY_ALGO_ECDSA
	elseif algo == "ecdh" then
		return gmime.GMIME_PUBKEY_ALGO_ECDH
	elseif algo == "eddsa" then
		return gmime.GMIME_PUBKEY_ALGO_EDDSA
	end
	-- elseif type(algo) == "table" then
	-- 	return bit_mask(algo, M.to_encoding)
	else
		return algo
	end
end

--- @param param string
--- @return integer
function M.to_param_encoding(param)
	if type(param) == "string" then
		param = param:lower()
		if param == "default" then
			return gmime.GMIME_PARAM_ENCODING_METHOD_DEFAULT
		elseif param == "rfc2231" then
			return gmime.GMIME_PARAM_ENCODING_METHOD_RFC2231
		elseif param == "rfc2047" then
			return gmime.GMIME_PARAM_ENCODING_METHOD_RFC2047
		end
	-- elseif type(param) == "table" then
	-- 	return bit_mask(param, M.to_param_encoding)
	else
		return param
	end
end

--- @param flags string
--- @return integer
function M.to_encryption_flags(flags)
	if type(flags) == "string" then
		flags = flags:lower()
		if flags == "none" then
			return gmime.GMIME_ENCRYPT_NONE
		elseif flags == "always_trust" then
			return gmime.GMIME_ENCRYPT_ALWAYS_TRUST
		elseif flags == "no_compress" then
			return gmime.GMIME_ENCRYPT_NO_COMPRESS
		elseif flags == "symmetric" then
			return gmime.GMIME_ENCRYPT_SYMMETRIC
		elseif flags == "throw_keyids" then
			return gmime.GMIME_ENCRYPT_THROW_KEYIDS
		end
	-- elseif type(flags) == "table" then
	-- 	return bit_mask(flags, M.to_encryption_flags)
	else
		return flags
	end
end

function M.to_decrytion_flag(flags)
	if type(flags) == "string" then
		flags = flags:lower()
		if flags == "none" then
			return gmime.GMIME_DECRYPT_NONE
		elseif flags == "session" then
			return gmime.GMIME_DECRYPT_EXPORT_SESSION_KEY
		elseif flags == "noverify" then
			return gmime.GMIME_DECRYPT_NO_VERIFY
		elseif flags == "keyserver" then
			return gmime.GMIME_DECRYPT_ENABLE_KEYSERVER_LOOKUPS
		elseif flags == "online" then
			return gmime.GMIME_DECRYPT_ENABLE_ONLINE_CERTIFICATE_CHECKS
		end
	-- elseif type(flags) == "table" then
	-- 	return bit_mask(flags, M.to_decrytion_flag)
	else
		return flags
	end
end

function M.to_verify_flags(flags)
	if type(flags) == "string" then
		flags = flags:lower()
		if flags == "none" then
			return gmime.GMIME_VERIFY_NONE
		elseif flags == "keyserver" then
			return gmime.GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS
		elseif flags == "online" then
			return gmime.GMIME_VERIFY_ENABLE_ONLINE_CERTIFICATE_CHECKS
		end
	-- elseif type(flags) == "table" then
	-- 	return bit_mask(flags, M.to_verify_flags)
	else
		return flags
	end
end


function M.to_filter_from(mode)
	if type(mode) == "string" then
		mode = mode:lower()
		if mode == "default" then
			return gmime.GMIME_FILTER_FROM_MODE_DEFAULT
		elseif mode == "escape" then
			return gmime.GMIME_FILTER_FROM_MODE_ESCAPE
		elseif mode == "armor" then
			return gmime.GMIME_FILTER_FROM_MODE_ARMOR
		end
	-- elseif type(mode) == "table" then
	-- 	return bit_mask(mode, M.to_filter_from)
	else
		return mode
	end
end

function M.show_encoding(encoding)
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

--- @param warning gmime.ParserWarning
--- @return string
function M.show_parser_warning(warning)
	if warning == gmime.GMIME_WARN_DUPLICATED_HEADER then
		return "DUPLICATED HEADER"
	elseif warning == gmime.GMIME_WARN_DUPLICATED_PARAMETER then
		return "DUPLICATED PARAMETER"
	elseif warning == gmime.GMIME_WARN_UNENCODED_8BIT_HEADER then
		return "UNENCODED 8BIT HEADER"
	elseif warning == gmime.GMIME_WARN_INVALID_CONTENT_TYPE then
		return "INVALID CONTENT TYPE"
	elseif warning == gmime.GMIME_WARN_INVALID_RFC2047_HEADER_VALUE then
		return "INVALID RFC2047 HEADER VALUE"
	elseif warning == gmime.GMIME_WARN_MALFORMED_MULTIPART then
		return "MALFORMED MULTIPART"
	elseif warning == gmime.GMIME_WARN_TRUNCATED_MESSAGE then
		return "TRUNCATED MESSAGE"
	elseif warning == gmime.GMIME_WARN_MALFORMED_MESSAGE then
		return "MALFORMED MESSAGE"
	elseif warning == gmime.GMIME_CRIT_INVALID_HEADER_NAME then
		return "INVALID HEADER NAME"
	elseif warning == gmime.GMIME_CRIT_CONFLICTING_HEADER then
		return "CONFLICTING HEADER"
	elseif warning == gmime.GMIME_CRIT_CONFLICTING_PARAMETER then
		return "CONFLICTING PARAMETER"
	elseif warning == gmime.GMIME_CRIT_MULTIPART_WITHOUT_BOUNDARY then
		return "MULTIPART WITHOUT BOUNDARY"
	elseif warning == gmime.GMIME_WARN_INVALID_PARAMETER then
		return "INVALID PARAMETER"
	elseif warning == gmime.GMIME_WARN_INVALID_ADDRESS_LIST then
		return "INVALID ADDRESS LIST"
	elseif warning == gmime.GMIME_CRIT_NESTING_OVERFLOW then
		return "NESTING OVERFLOW"
	elseif warning == gmime.GMIME_WARN_PART_WITHOUT_CONTENT then
		return "PART WITHOUT CONTENT"
	elseif warning == gmime.GMIME_CRIT_PART_WITHOUT_HEADERS_OR_CONTENT then
		return "PART WITHOUT HEADERS OR CONTENT"
	end
end


--- @param warning gmime.ParserWarning
--- @return number
function M.parser_warning_level(warning)
	if warning == gmime.GMIME_WARN_DUPLICATED_HEADER then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_DUPLICATED_PARAMETER then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_UNENCODED_8BIT_HEADER then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_INVALID_CONTENT_TYPE then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_INVALID_RFC2047_HEADER_VALUE then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_MALFORMED_MULTIPART then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_TRUNCATED_MESSAGE then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_MALFORMED_MESSAGE then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_CRIT_INVALID_HEADER_NAME then
		return vim.log.levels.ERROR
	elseif warning == gmime.GMIME_CRIT_CONFLICTING_HEADER then
		return vim.log.levels.ERROR
	elseif warning == gmime.GMIME_CRIT_CONFLICTING_PARAMETER then
		return vim.log.levels.ERROR
	elseif warning == gmime.GMIME_CRIT_MULTIPART_WITHOUT_BOUNDARY then
		return vim.log.levels.ERROR
	elseif warning == gmime.GMIME_WARN_INVALID_PARAMETER then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_WARN_INVALID_ADDRESS_LIST then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_CRIT_NESTING_OVERFLOW then
		return vim.log.levels.ERROR
	elseif warning == gmime.GMIME_WARN_PART_WITHOUT_CONTENT then
		return vim.log.levels.WARN
	elseif warning == gmime.GMIME_CRIT_PART_WITHOUT_HEADERS_OR_CONTENT then
		return vim.log.levels.ERROR
	end
end

--- @param choice string
--- @return integer
local function to_validate(choice)
	choice = choice:lower()
	if choice == "valid" then
		return gmime.GMIME_SIGNATURE_STATUS_VALID
	elseif choice == "green" then
		return gmime.GMIME_SIGNATURE_STATUS_GREEN
	elseif choice == "red" then
		return gmime.GMIME_SIGNATURE_STATUS_RED
	elseif choice == "revoked" then
		return gmime.GMIME_SIGNATURE_STATUS_KEY_REVOKED
	elseif choice == "key-expired" then
		return gmime.GMIME_SIGNATURE_STATUS_KEY_EXPIRED
	elseif choice == "sig-expired" then
		return gmime.GMIME_SIGNATURE_STATUS_SIG_EXPIRED
	elseif choice == "missing" then
		return gmime.GMIME_SIGNATURE_STATUS_KEY_MISSING
	elseif choice == "crl-missing" then
		return gmime.GMIME_SIGNATURE_STATUS_CRL_MISSING
	elseif choice == "crl-old" then
		return gmime.GMIME_SIGNATURE_STATUS_CRL_TOO_OLD
	elseif choice == "bad-policy" then
		return gmime.GMIME_SIGNATURE_STATUS_BAD_POLICY
	elseif choice == "error" then
		return gmime.GMIME_SIGNATURE_STATUS_SYS_ERROR
	elseif choice == "conflict" then
		return gmime.GMIME_SIGNATURE_STATUS_TOFU_CONFLICT
	end
end

function M.validate(sig, choices)
	if type(choices) == "string" then
		return bit.band(sig, to_validate(choices)) ~= 0
	else
		return bit.band(sig, choices) ~= 0
	end
end

--- @param name string
--- @return integer
function M.gpg_digest_id(name)
	name = name:lower()
	if name == "md2" then
		return gmime.GMIME_DIGEST_ALGO_MD2
	elseif name == "md4" then
		return gmime.GMIME_DIGEST_ALGO_MD4
	elseif name == "md5" then
		return gmime.GMIME_DIGEST_ALGO_MD5
	elseif name == "sha1" then
		return gmime.GMIME_DIGEST_ALGO_SHA1
	elseif name == "sha224" then
		return gmime.GMIME_DIGEST_ALGO_SHA224
	elseif name == "sha256" then
		return gmime.GMIME_DIGEST_ALGO_SHA256
	elseif name == "sha384" then
		return gmime.GMIME_DIGEST_ALGO_SHA384
	elseif name == "sha512" then
		return gmime.GMIME_DIGEST_ALGO_SHA512
	elseif name == "ripemd160" then
		return gmime.GMIME_DIGEST_ALGO_RIPEMD160
	elseif name == "tiger192" then
		return gmime.GMIME_DIGEST_ALGO_TIGER192
	elseif name == "haval-5-160" then
		return gmime.GMIME_DIGEST_ALGO_HAVAL5160
	end
	return gmime.GMIME_DIGEST_ALGO_DEFAULT
end

--- @param int integer
--- @return string
function M.gpg_digest_name(int)
	if int == gmime.GMIME_DIGEST_ALGO_MD2 then
		return "md2"
	elseif int == gmime.GMIME_DIGEST_ALGO_MD4 then
		return "md4"
	elseif int == gmime.GMIME_DIGEST_ALGO_MD5 then
		return "md5"
	elseif int == gmime.GMIME_DIGEST_ALGO_SHA1 then
		return "sha1"
	elseif int == gmime.GMIME_DIGEST_ALGO_SHA224 then
		return "sha224"
	elseif int == gmime.GMIME_DIGEST_ALGO_SHA256 then
		return "sha256"
	elseif int == gmime.GMIME_DIGEST_ALGO_SHA384 then
		return "sha384"
	elseif int == gmime.GMIME_DIGEST_ALGO_SHA512 then
		return "sha512"
	elseif int == gmime.GMIME_DIGEST_ALGO_RIPEMD160 then
		return "ripemd160"
	elseif int == gmime.GMIME_DIGEST_ALGO_TIGER192 then
		return "tiger192"
	elseif int == gmime.GMIME_DIGEST_ALGO_HAVAL5160 then
		return "haval-5-160"
	end
	return "pgp-sha1"
end

function M.best_flag(str)
	str = str:lower()
	if str == "charset" then
		return gmime.GMIME_FILTER_BEST_CHARSET
	elseif str == "encoding" then
		return gmime.GMIME_FILTER_BEST_ENCODING
	end
end

function M.to_gzip_mode(mode)
	mode = mode:lower()
	if mode == "zip" then
		return gmime.GMIME_FILTER_GZIP_MODE_ZIP
	elseif mode == "unzip" then
		return gmime.GMIME_FILTER_GZIP_MODE_UNZIP
	end
end

return M
