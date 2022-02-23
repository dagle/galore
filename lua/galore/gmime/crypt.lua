local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

-- typedef GMimeCryptoContext * (* GMimeCryptoContextNewFunc) (void);

-- typedef gboolean (* GMimePasswordRequestFunc) (GMimeCryptoContext *ctx, const char *user_id, const char *prompt,
-- 					       gboolean reprompt, GMimeStream *response, GError **err);

--- @param protocol string
--- @param func fun():gmime.CryptoContext
function M.g_mime_crypto_context_register(protocol, func)
	gmime.g_mime_crypto_context_register(protocol, func)
end

--- @param ctx gmime.CryptoContext
--- @param func fun(gmime.CryptoContext, string, string, boolean, gmime.Stream):boolean
function M.g_mime_crypto_context_set_request_password(ctx, func)
	gmime.g_mime_crypto_context_set_request_password(ctx, func)
end
--
-- GMimeCryptoContext *g_mime_crypto_context_new (const char *protocol);
--- @param protocol string
--- @return @gmime.CryptoContext
function M.g_mime_crypto_context_new(protocol)
	return gmime.g_mime_crypto_context_new(protocol)
end
--
-- GMimeDigestAlgo g_mime_crypto_context_digest_id (GMimeCryptoContext *ctx, const char *name);
--- @param ctx gmime.CryptoContext
--- @param name string
--- @return XXX
function M.g_mime_crypto_context_digest_id(ctx, name)
	return gmime.g_mime_crypto_context_digest_id(ctx, name)
end
-- const char *g_mime_crypto_context_digest_name (GMimeCryptoContext *ctx, GMimeDigestAlgo digest);
--- @param ctx gmime.CryptoContext
--- @param digest XXX
--- @return string
function M.g_mime_crypto_context_digest_name(ctx, digest)
	return ffi.string(gmime.g_mime_crypto_context_digest_name(ctx, digest))
end
--
-- /* protocol routines */
-- const char *g_mime_crypto_context_get_signature_protocol (GMimeCryptoContext *ctx);
--- @param ctx gmime.CryptoContext
--- @return string
function M.g_mime_crypto_context_get_signature_protocol(ctx)
	return ffi.string(gmime.g_mime_crypto_context_get_signature_protocol(ctx))
end
-- const char *g_mime_crypto_context_get_encryption_protocol (GMimeCryptoContext *ctx);
--- @param ctx gmime.CryptoContext
--- @return string
function M.g_mime_crypto_context_get_encryption_protocol(ctx)
	return ffi.string(gmime.g_mime_crypto_context_get_encryption_protocol(ctx))
end

-- const char *g_mime_crypto_context_get_key_exchange_protocol (GMimeCryptoContext *ctx);
--- @param ctx gmime.CryptoContext
--- @return string
function M.g_mime_crypto_context_get_key_exchange_protocol(ctx)
	return ffi.string(gmime.g_mime_crypto_context_get_key_exchange_protocol())
end

-- /* crypto routines */
-- int g_mime_crypto_context_sign (GMimeCryptoContext *ctx, gboolean detach, const char *userid,
-- 				GMimeStream *istream, GMimeStream *ostream, GError **err);

--- @param ctx gmime.CryptoContext
--- @param detach boolean
--- @param userid string
--- @param instream gmime.Stream
--- @param outstream gmime.Stream
--- @return number, gmime.Error
function M.g_mime_crypto_context_sign(ctx, detach, userid, instream, outstream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_sign(ctx, detach, userid, instream, outstream, err)
	return ret, err[0]
end
--
-- GMimeSignatureList *g_mime_crypto_context_verify (GMimeCryptoContext *ctx, GMimeVerifyFlags flags,
-- 						  GMimeStream *istream, GMimeStream *sigstream,
-- 						  GMimeStream *ostream, GError **err);

--- @param ctx gmime.CryptoContext
--- @param flags XXX
--- @param instream gmime.Stream
--- @param sigstream gmime.Stream
--- @param outstream gmime.Stream
--- @return gmime.SignatureList, gmime.Error
function M.g_mime_crypto_context_verify(ctx, flags, instream, sigstream, outstream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_verify(ctx, flags, instream, sigstream, outstream, err)
	return ret, err[0]
end
--
-- int g_mime_crypto_context_encrypt (GMimeCryptoContext *ctx, gboolean sign, const char *userid,
-- 				   GMimeEncryptFlags flags, GPtrArray *recipients,
-- 				   GMimeStream *istream, GMimeStream *ostream,
-- 				   GError **err);
--- @param ctx gmime.CryptoContext
--- @param flags XXX
--- @param recipients string[]
--- @param instream gmime.Stream
--- @param outstream gmime.Stream
--- @return number, gmime.Error
function M.g_mime_crypto_context_encrypt(ctx, sign, userid, flags, recipients, instream, outstream)
	local array = gmime.g_ptr_array_sized_new(0)
	for _, rep in ipairs(recipients) do
		gmime.g_ptr_array_add(array, ffi.cast("gpointer", rep))
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_encrypt(ctx, sign, userid, flags, array, instream, outstream, err)
	gmime.g_ptr_array_free(array, false)
	return ret, err[0]
end

--
-- GMimeDecryptResult *g_mime_crypto_context_decrypt (GMimeCryptoContext *ctx, GMimeDecryptFlags flags,
-- 						   const char *session_key, GMimeStream *istream,
-- 						   GMimeStream *ostream, GError **err);

--- @param ctx gmime.CryptoContext
--- @param flags XXX
--- @param session_key string
--- @param istream gmime.Stream
--- @param ostream gmime.Stream
--- @return gmime.DecryptResult, gmime.Error
function M.g_mime_crypto_context_decrypt(ctx, flags, session_key, istream, ostream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_decrypt(ctx, flags, session_key, istream, ostream, err)
	return ret, err[0]
end
--
-- /* key/certificate routines */
-- int g_mime_crypto_context_import_keys (GMimeCryptoContext *ctx, GMimeStream *istream, GError **err);
--- @param ctx gmime.CryptoContext
--- @param istream gmime.Stream
--- @return number, gmime.Error
function M.g_mime_crypto_context_import_keys(ctx, istream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_import_keys(ctx, istream, err)
	return ret, err[0]
end
--
-- int g_mime_crypto_context_export_keys (GMimeCryptoContext *ctx, const char *keys[],
-- 				       GMimeStream *ostream, GError **err);
--- @param ctx gmime.CryptoContext
--- @param keys string[]
--- @param ostream gmime.Stream
--- @return number, gmime.Error
function M.g_mime_crypto_context_export_keys(ctx, keys, ostream)
	local array = ffi.new("char *[?]", #keys)
	for i, key in ipairs(keys) do
		array[i-1] = key
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_export_keys(ctx, array, ostream, err)
	return ret, err[0]
end
--
--
-- GMimeDecryptResult *g_mime_decrypt_result_new (void);
--- @return gmime.DecryptResult
function M.g_mime_decrypt_result_new()
	return gmime.g_mime_decrypt_result_new()
end
--
-- void g_mime_decrypt_result_set_recipients (GMimeDecryptResult *result, GMimeCertificateList *recipients);
--- @param result gmime.DecryptResult
--- @param recipients gmime.CertificateList
function M.g_mime_decrypt_result_set_recipients(result, recipients)
	gmime.g_mime_decrypt_result_set_recipients(result, recipients)
end

-- GMimeCertificateList *g_mime_decrypt_result_get_recipients (GMimeDecryptResult *result);
--- @param result gmime.DecryptResult
--- @return gmime.CertificateList
function M.g_mime_decrypt_result_get_recipients(result)
	return gmime.g_mime_decrypt_result_get_recipients(result)
end
--
-- void g_mime_decrypt_result_set_signatures (GMimeDecryptResult *result, GMimeSignatureList *signatures);
--- @param result gmime.DecryptResult
--- @param signatures gmime.SignatureList
function M.g_mime_decrypt_result_set_signatures(result, signatures)
	gmime.g_mime_decrypt_result_set_signatures(result, signatures)
end

-- GMimeSignatureList *g_mime_decrypt_result_get_signatures (GMimeDecryptResult *result);
--- @param result gmime.DecryptResult
--- @return gmime.SignatureList
function M.g_mime_decrypt_result_get_signatures(result)
	gmime.g_mime_decrypt_result_get_signatures(result)
end

-- void g_mime_decrypt_result_set_cipher (GMimeDecryptResult *result, GMimeCipherAlgo cipher);
--- @param result gmime.DecryptResult
--- @param cipher XXX
function M.g_mime_decrypt_result_set_cipher(result, cipher)
	gmime.g_mime_decrypt_result_set_cipher(result, cipher)
end

-- GMimeCipherAlgo g_mime_decrypt_result_get_cipher (GMimeDecryptResult *result);
--- @param result gmime.DecryptResult
--- @return XXX
function M.g_mime_decrypt_result_get_cipher(result)
	gmime.g_mime_decrypt_result_get_cipher(result)
end

-- void g_mime_decrypt_result_set_mdc (GMimeDecryptResult *result, GMimeDigestAlgo mdc);
--- @param result gmime.DecryptResult
--- @param mdc XXX
function M.g_mime_decrypt_result_set_mdc(result, mdc)
	gmime.g_mime_decrypt_result_set_mdc(result, mdc)
end

-- GMimeDigestAlgo g_mime_decrypt_result_get_mdc (GMimeDecryptResult *result);
--- @param result gmime.DecryptResult
--- @return XXX
function M.g_mime_decrypt_result_get_mdc(result)
	gmime.g_mime_decrypt_result_get_mdc(result)
end

-- void g_mime_decrypt_result_set_session_key (GMimeDecryptResult *result, const char *session_key);
--- @param result gmime.DecryptResult
--- @param session_key string
function M.g_mime_decrypt_result_set_session_key(result, session_key)
	gmime.g_mime_decrypt_result_set_session_key(result, session_key)
end

-- const char *g_mime_decrypt_result_get_session_key (GMimeDecryptResult *result);
--- @param result gmime.DecryptResult
--- @retun string
function M.g_mime_decrypt_result_get_session_key(result)
	gmime.g_mime_decrypt_result_get_session_key(result)
end

-- GMimeAutocryptHeader *g_mime_autocrypt_header_new (void);
--- @return gmime.AutocryptHeader
function M.g_mime_autocrypt_header_new()
	return gmime.g_mime_autocrypt_header_new()
end

-- GMimeAutocryptHeader *g_mime_autocrypt_header_new_from_string (const char *string);
--- @param str string
--- @return gmime.AutocryptHeader
function M.g_mime_autocrypt_header_new_from_string(str)
	gmime.g_mime_autocrypt_header_new_from_string(str)
end
--
-- void g_mime_autocrypt_header_set_address (GMimeAutocryptHeader *ah, InternetAddressMailbox *address);
--- @param ah gmime.AutocryptHeader
--- @param addresss gmime.InternetAddressMailbox
function M.g_mime_autocrypt_header_set_address(ah, addresss)
	gmime.g_mime_autocrypt_header_set_address(ah, addresss)
end

-- InternetAddressMailbox *g_mime_autocrypt_header_get_address (GMimeAutocryptHeader *ah);
--- @param ah gmime.AutocryptHeader
--- @return gmime.InternetAddressMailbox
function M.g_mime_autocrypt_header_get_address(ah)
	gmime.g_mime_autocrypt_header_get_address(ah)
end

-- void g_mime_autocrypt_header_set_address_from_string (GMimeAutocryptHeader *ah, const char *address);
--- @param ah gmime.AutocryptHeader
--- @param address string
function M.g_mime_autocrypt_header_set_address_from_string(ah, address)
	gmime.g_mime_autocrypt_header_set_address_from_string(ah, address)
end

--- @param ah gmime.AutocryptHeader
--- @return string
-- const char *g_mime_autocrypt_header_get_address_as_string (GMimeAutocryptHeader *ah);
function M.g_mime_autocrypt_header_get_address_as_string(ah)
	return ffi.string(gmime.g_mime_autocrypt_header_get_address_as_string(ah))
end

-- void g_mime_autocrypt_header_set_prefer_encrypt (GMimeAutocryptHeader *ah, GMimeAutocryptPreferEncrypt pref);
--- @param ah gmime.AutocryptHeader
--- @param pref XXX
function M.g_mime_autocrypt_header_set_prefer_encrypt(ah, pref)
	gmime.g_mime_autocrypt_header_set_prefer_encrypt(ah, pref)
end

--- @param ah gmime.AutocryptHeader
--- @return XXX
-- GMimeAutocryptPreferEncrypt g_mime_autocrypt_header_get_prefer_encrypt (GMimeAutocryptHeader *ah);
function M.g_mime_autocrypt_header_get_prefer_encrypt(ah)
	gmime.g_mime_autocrypt_header_get_prefer_encrypt(ah)
end

--
-- void g_mime_autocrypt_header_set_keydata (GMimeAutocryptHeader *ah, GBytes *data);
--- XXX
function M.g_mime_autocrypt_header_set_keydata()
	gmime.g_mime_autocrypt_header_set_keydata()
end
--- XXX
-- GBytes *g_mime_autocrypt_header_get_keydata (GMimeAutocryptHeader *ah);
function M.g_mime_autocrypt_header_get_keydata()
	gmime.g_mime_autocrypt_header_get_keydata()
end

-- void g_mime_autocrypt_header_set_effective_date (GMimeAutocryptHeader *ah, GDateTime *effective_date);
--- @param ah gmime.AutocryptHeader
--- @param date number
--- XXX date
function M.g_mime_autocrypt_header_set_effective_date(ah, date)
	gmime.g_mime_autocrypt_header_set_effective_date(ah, date)
end

-- GDateTime *g_mime_autocrypt_header_get_effective_date (GMimeAutocryptHeader *ah);
--- @param ah gmime.AutocryptHeader
--- @return number
--- XXX date
function M.g_mime_autocrypt_header_get_effective_date(ah)
	gmime.g_mime_autocrypt_header_get_effective_date(ah)
end

-- char *g_mime_autocrypt_header_to_string (GMimeAutocryptHeader *ah, gboolean gossip);
--- @param ah gmime.AutocryptHeader
--- @param gossip boolean
--- @return string
function M.g_mime_autocrypt_header_to_string(ah, gossip)
	local mem = gmime.g_mime_autocrypt_header_to_string(ah, gossip)
	return convert.strdup(mem)
end

-- gboolean g_mime_autocrypt_header_is_complete (GMimeAutocryptHeader *ah);
--- @param ah gmime.AutocryptHeader
--- @return boolean
function M.g_mime_autocrypt_header_is_complete(ah)
	return gmime.g_mime_autocrypt_header_is_complete(ah)
end

-- int g_mime_autocrypt_header_compare (GMimeAutocryptHeader *ah1, GMimeAutocryptHeader *ah2);
--- @param ah1 gmime.AutocryptHeader
--- @param ah2 gmime.AutocryptHeader
--- @return number
function M.g_mime_autocrypt_header_compare(ah1, ah2)
	return gmime.g_mime_autocrypt_header_compare(ah1, ah2)
end

-- void g_mime_autocrypt_header_clone (GMimeAutocryptHeader *dst, GMimeAutocryptHeader *src);
--- @param dst gmime.AutocryptHeader
--- @param src gmime.AutocryptHeader
function M.g_mime_autocrypt_header_clone(dst, src)
	gmime.g_mime_autocrypt_header_clone(dst, src)
end
--
-- GMimeAutocryptHeaderList *g_mime_autocrypt_header_list_new (void);
--- @return gmime.AutocryptHeaderList
function M.g_mime_autocrypt_header_list_new()
	return gmime.g_mime_autocrypt_header_list_new()
end

-- guint g_mime_autocrypt_header_list_add_missing_addresses (GMimeAutocryptHeaderList *list, InternetAddressList *addresses);
--- @param list gmime.AutocryptHeaderList
--- @param addresses gmime.InternetAddressList
--- @return number
function M.g_mime_autocrypt_header_list_add_missing_addresses(list, addresses)
	return gmime.g_mime_autocrypt_header_list_add_missing_addresses(list, addresses)
end

-- void g_mime_autocrypt_header_list_add (GMimeAutocryptHeaderList *list, GMimeAutocryptHeader *header);
--- @param list gmime.AutocryptHeaderList
--- @param header gmime.AutocryptHeader
function M.g_mime_autocrypt_header_list_add(list, header)
	gmime.g_mime_autocrypt_header_list_add(list, header)
end
--
-- guint g_mime_autocrypt_header_list_get_count (GMimeAutocryptHeaderList *list);
--- @param list list gmime.AutocryptHeaderList
function M.g_mime_autocrypt_header_list_get_count(list)
	return gmime.g_mime_autocrypt_header_list_get_count(list)
end
-- GMimeAutocryptHeader *g_mime_autocrypt_header_list_get_header_at (GMimeAutocryptHeaderList *list, guint index);
--- @param list gmime.AutocryptHeaderList
--- @param index number
--- @return gmime.AutocryptHeader
function M.g_mime_autocrypt_header_list_get_header_at(list, index)
	return gmime.g_mime_autocrypt_header_list_get_header_at(list, index)
end

-- GMimeAutocryptHeader *g_mime_autocrypt_header_list_get_header_for_address (GMimeAutocryptHeaderList *list, InternetAddressMailbox *mailbox);
--- @param list gmime.AutocryptHeaderList
--- @param mb gmime.InternetAddressMailbox
--- @return gmime.AutocryptHeader
function M.g_mime_autocrypt_header_list_get_header_for_address(list, mb)
	return gmime.g_mime_autocrypt_header_list_get_header_for_address(list, mb)
end

-- void g_mime_autocrypt_header_list_remove_incomplete (GMimeAutocryptHeaderList *list);
--- @param list gmime.AutocryptHeaderList
function M.g_mime_autocrypt_header_list_remove_incomplete(list)
	gmime.g_mime_autocrypt_header_list_remove_incomplete(list)
end
-- GMimeSignature *g_mime_signature_new (void);
--- @return gmime.Signature
function M.g_mime_signature_new()
	return gmime.g_mime_signature_new()
end
--
-- void g_mime_signature_set_certificate (GMimeSignature *sig, GMimeCertificate *cert);
--- @param sig gmime.Signature
--- @param cert gmime.Certificate
function M.g_mime_signature_set_certificate(sig, cert)
	gmime.g_mime_signature_set_certificate(sig, cert)
end
-- GMimeCertificate *g_mime_signature_get_certificate (GMimeSignature *sig);
--- @param sig gmime.Signature
--- @return gmime.Certificate
function M.g_mime_signature_get_certificate(sig)
	return gmime.g_mime_signature_get_certificate(sig)
end
--
-- void g_mime_signature_set_status (GMimeSignature *sig, GMimeSignatureStatus status);
--- @param sig gmime.Signature
--- @param status gmime.SignatureStatus
function M.g_mime_signature_set_status(sig, status)
	gmime.g_mime_signature_set_status(sig, status)
end
-- GMimeSignatureStatus g_mime_signature_get_status (GMimeSignature *sig);
--- @param sig gmime.Signature
--- @return gmime.SignatureStatus
function M.g_mime_signature_get_status(sig)
	return gmime.g_mime_signature_get_status(sig)
end

-- void g_mime_signature_set_created (GMimeSignature *sig, time_t created);
--- @param sig gmime.Signature
--- @param created number
--- XXX
function M.g_mime_signature_set_created(sig, created)
	gmime.g_mime_signature_set_created(sig, created)
end

-- time_t g_mime_signature_get_created (GMimeSignature *sig);
--- @param sig gmime.Signature
--- @return number
--- XXX
function M.g_mime_signature_get_created(sig)
	return gmime.g_mime_signature_get_created(sig)
end

-- gint64 g_mime_signature_get_created64 (GMimeSignature *sig);
--- @param sig gmime.Signature
--- @return number
function M.g_mime_signature_get_created64(sig)
	return gmime.g_mime_signature_get_created64(sig)
end

--- @param sig gmime.Signature
--- @param expire number
--- XXX
-- void g_mime_signature_set_expires (GMimeSignature *sig, time_t expires);
function M.g_mime_signature_set_expires(sig, expire)
	gmime.g_mime_signature_set_expires(sig, expire)
end

--- @param sig gmime.Signature
--- @return number
--- XXX
-- time_t g_mime_signature_get_expires (GMimeSignature *sig);
function M.g_mime_signature_get_expires(sig)
	return gmime.g_mime_signature_get_expires(sig)
end

-- gint64 g_mime_signature_get_expires64 (GMimeSignature *sig);
--- @param sig gmime.Signature
--- @return number
function M.g_mime_signature_get_expires64(sig)
	return gmime.g_mime_signature_get_expires64(sig)
end

-- GMimeSignatureList *g_mime_signature_list_new (void);
--- @return gmime.SignatureList
function M.g_mime_signature_list_new()
	return gmime.g_mime_signature_list_new()
end

-- int g_mime_signature_list_length (GMimeSignatureList *list);
--- @param list gmime.SignatureList
--- @return number
function M.g_mime_signature_list_length(list)
	return gmime.g_mime_signature_list_length(list)
end

-- void g_mime_signature_list_clear (GMimeSignatureList *list);
--- @param list gmime.SignatureList
function M.g_mime_signature_list_clear(list)
	gmime.g_mime_signature_list_clear(list)
end

-- int g_mime_signature_list_add (GMimeSignatureList *list, GMimeSignature *sig);
--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return number
function M.g_mime_signature_list_add(list, sig)
	return gmime.g_mime_signature_list_add(list, sig)
end

-- void g_mime_signature_list_insert (GMimeSignatureList *list, int index, GMimeSignature *sig);
--- @param list gmime.SignatureList
--- @param index number
--- @param sig gmime.Signature
function M.g_mime_signature_list_insert(list, index, sig)
	gmime.g_mime_signature_list_insert(list, index, sig)
end

-- gboolean g_mime_signature_list_remove (GMimeSignatureList *list, GMimeSignature *sig);
--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return boolean
function M.g_mime_signature_list_remove(list, sig)
	return gmime.g_mime_signature_list_remove(list, sig)
end

-- gboolean g_mime_signature_list_remove_at (GMimeSignatureList *list, int index);
--- @param list gmime.SignatureList
--- @param index number
--- @return boolean
function M.g_mime_signature_list_remove_at(list, index)
	return gmime.g_mime_signature_list_remove_at(list, index)
end

-- gboolean g_mime_signature_list_contains (GMimeSignatureList *list, GMimeSignature *sig);
--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return boolean
function M.g_mime_signature_list_contains(list, sig)
	return gmime.g_mime_signature_list_contains(list, sig)
end

-- int g_mime_signature_list_index_of (GMimeSignatureList *list, GMimeSignature *sig);
--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return number
function M.g_mime_signature_list_index_of(list, sig)
	return gmime.g_mime_signature_list_index_of(list, sig)
end

-- GMimeSignature *g_mime_signature_list_get_signature (GMimeSignatureList *list, int index);
--- @param list gmime.SignatureList
--- @param index number
--- @return gmime.Signature
function M.g_mime_signature_list_get_signature(list, index)
	return gmime.g_mime_signature_list_get_signature(list, index)
end

-- GMimeCryptoContext *g_mime_pkcs7_context_new (void);
--- @return gmime.CryptoContext
function M.g_mime_pkcs7_context_new(list, sig)
	return gmime.g_mime_pkcs7_context_new(list, sig)
end

-- void g_mime_signature_list_set_signature (GMimeSignatureList *list, int index, GMimeSignature *sig);
--- @param list gmime.SignatureList
--- @param index number
--- @param sig gmime.Signature
function M.g_mime_signature_list_set_signature(list, index, sig)
	gmime.g_mime_signature_list_set_signature(list, index, sig)
end

-- GMimeApplicationPkcs7Mime *g_mime_application_pkcs7_mime_new (GMimeSecureMimeType type);
function M.g_mime_application_pkcs7_mime_new(type)
	return gmime.g_mime_application_pkcs7_mime_new(type)
end
--
-- GMimeSecureMimeType g_mime_application_pkcs7_mime_get_smime_type (GMimeApplicationPkcs7Mime *pkcs7_mime);
function M.g_mime_application_pkcs7_mime_get_smime_type(pkcs7_mime)
	return gmime.g_mime_application_pkcs7_mime_get_smime_type(pkcs7_mime)
end
--
-- GMimeApplicationPkcs7Mime *g_mime_application_pkcs7_mime_encrypt (GMimeObject *entity, GMimeEncryptFlags flags,
-- 								  GPtrArray *recipients, GError **err);
function M.g_mime_application_pkcs7_mime_encrypt(entity, flags, recipients)
	local array = gmime.g_ptr_array_sized_new(0)
	for _, rep in ipairs(recipients) do
		gmime.g_ptr_array_add(array, ffi.cast("gpointer", rep))
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_encrypt(entity, flags, array, err)
	gmime.g_ptr_array_free(array, false)
	return ret, err[0]
end
--
-- GMimeObject *g_mime_application_pkcs7_mime_decrypt (GMimeApplicationPkcs7Mime *pkcs7_mime,
-- 						    GMimeDecryptFlags flags, const char *session_key,
-- 						    GMimeDecryptResult **result, GError **err);
function M.g_mime_application_pkcs7_mime_decrypt(pkcs7_mime, flags, session_key)
	local err = ffi.new("GError*[1]")
	local result = ffi.new("GMimeDecryptResult*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_encrypt(pkcs7_mime, flags, session_key, result, err)
	return ret, result[0], err[0]
end
--
-- GMimeApplicationPkcs7Mime *g_mime_application_pkcs7_mime_sign (GMimeObject *entity, const char *userid, GError **err);
function M.g_mime_application_pkcs7_mime_sign(entity, userid)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_sign(entity, userid, err)
	return ret, err[0]
end
--
-- GMimeSignatureList *g_mime_application_pkcs7_mime_verify (GMimeApplicationPkcs7Mime *pkcs7_mime, GMimeVerifyFlags flags,
-- 							  GMimeObject **entity, GError **err);
function M.g_mime_application_pkcs7_mime_verify(pkcs7_mime, flags)
	local err = ffi.new("GError*[1]")
	local objects = ffi.new("GMimeObject*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_verify(pkcs_7_mime, flags, objects, err)
	return ret, objects[0], err[0]
end
--
-- GMimeCryptoContext *g_mime_gpg_context_new (void);
function M.g_mime_gpg_context_new()
	return gmime.g_mime_gpg_context_new()
end
--
-- GMimeCertificate *g_mime_certificate_new (void);
function M.g_mime_certificate_new()
	return gmime.g_mime_certificate_new()
end
--
-- void g_mime_certificate_set_trust (GMimeCertificate *cert, GMimeTrust trust);
function M.g_mime_certificate_set_trust(cert, trust)
	gmime.g_mime_certificate_set_trust(cert, trust)
end
-- GMimeTrust g_mime_certificate_get_trust (GMimeCertificate *cert);
function M.g_mime_certificate_get_trust(cert)
	return gmime.g_mime_certificate_get_trust(cert)
end
--
-- void g_mime_certificate_set_pubkey_algo (GMimeCertificate *cert, GMimePubKeyAlgo algo);
function M.g_mime_certificate_set_pubkey_algo(cert, algo)
	gmime.g_mime_certificate_set_pubkey_algo(cert, algo)
end
-- GMimePubKeyAlgo g_mime_certificate_get_pubkey_algo (GMimeCertificate *cert);
function M.g_mime_certificate_get_pubkey_algo(cert)
	return gmime.g_mime_certificate_get_pubkey_algo(cert)
end
--
-- void g_mime_certificate_set_digest_algo (GMimeCertificate *cert, GMimeDigestAlgo algo);
function M.g_mime_certificate_set_digest_algo(cert, algo)
	return gmime.g_mime_certificate_set_digest_algo(cert, algo)
end
-- GMimeDigestAlgo g_mime_certificate_get_digest_algo (GMimeCertificate *cert);
function M.g_mime_certificate_get_digest_algo(cert)
	return gmime.g_mime_certificate_get_digest_algo(cert)
end
--
-- void g_mime_certificate_set_issuer_serial (GMimeCertificate *cert, const char *issuer_serial);
function M.g_mime_certificate_set_issuer_serial(cert, issuer)
	gmime.g_mime_certificate_set_issuer_serial(cert, issuer)
end
-- const char *g_mime_certificate_get_issuer_serial (GMimeCertificate *cert);
function M.g_mime_certificate_get_issuer_serial(cert)
	return ffi.string(gmime.g_mime_certificate_get_issuer_serial(cert))
end
--
-- void g_mime_certificate_set_issuer_name (GMimeCertificate *cert, const char *issuer_name);
function M.g_mime_certificate_set_issuer_name(cert, issuer)
	gmime.g_mime_certificate_set_issuer_name(cert, issuer)
end
-- const char *g_mime_certificate_get_issuer_name (GMimeCertificate *cert);
function M.g_mime_certificate_get_issuer_name(cert)
	gmime.g_mime_certificate_get_issuer_name(cert)
end
--
-- void g_mime_certificate_set_fingerprint (GMimeCertificate *cert, const char *fingerprint);
function M.g_mime_certificate_set_fingerprint(cert, fingerprint)
	gmime.g_mime_certificate_set_fingerprint(cert, fingerprint)
end
-- const char *g_mime_certificate_get_fingerprint (GMimeCertificate *cert);
function M.g_mime_certificate_get_fingerprint()
	return ffi.string(gmime.g_mime_certificate_get_fingerprint(cert))
end
--
-- void g_mime_certificate_set_key_id (GMimeCertificate *cert, const char *key_id);
function M.g_mime_certificate_set_key_id(cert, keyid)
	gmime.g_mime_certificate_set_key_id(cert, keyid)
end
-- const char *g_mime_certificate_get_key_id (GMimeCertificate *cert);
function M.g_mime_certificate_get_key_id(cert)
	return ffi.string(gmime.g_mime_certificate_get_key_id(cert))
end
--
-- void g_mime_certificate_set_email (GMimeCertificate *cert, const char *email);
function M.g_mime_certificate_set_email(cert, email)
	gmime.g_mime_certificate_set_email(cert, email)
end
-- const char *g_mime_certificate_get_email (GMimeCertificate *cert);
function M.g_mime_certificate_get_email(cert)
	return ffi.string(gmime.g_mime_certificate_get_email(cert))
end
--
-- void g_mime_certificate_set_name (GMimeCertificate *cert, const char *name);
function M.g_mime_certificate_set_name(cert, name)
	gmime.g_mime_certificate_set_name(cert, name)
end
-- const char *g_mime_certificate_get_name (GMimeCertificate *cert);
function M.g_mime_certificate_get_name(cert)
	return ffi.string(gmime.g_mime_certificate_get_name(cert))
end
--
-- void g_mime_certificate_set_user_id (GMimeCertificate *cert, const char *user_id);
function M.g_mime_certificate_set_user_id(cert, userid)
	gmime.g_mime_certificate_set_user_id(cert, userid)
end
-- const char *g_mime_certificate_get_user_id (GMimeCertificate *cert);
function M.g_mime_certificate_get_user_id(cert)
	gmime.g_mime_certificate_get_user_id(cert)
end
--
-- void g_mime_certificate_set_id_validity (GMimeCertificate *cert, GMimeValidity validity);
function M.g_mime_certificate_set_id_validity(cert, valaidity)
	gmime.g_mime_certificate_set_id_validity(cert, valaidity)
end
-- GMimeValidity g_mime_certificate_get_id_validity (GMimeCertificate *cert);
function M.g_mime_certificate_get_id_validity(cert)
	return gmime.g_mime_certificate_get_id_validity(cert)
end
--
-- void g_mime_certificate_set_created (GMimeCertificate *cert, time_t created);
function M.g_mime_certificate_set_created(cert, created)
	gmime.g_mime_certificate_set_created(cert, created)
end
-- time_t g_mime_certificate_get_created (GMimeCertificate *cert);
function M.g_mime_certificate_get_created(cert)
	return gmime.g_mime_certificate_get_created(cert)
end
-- gint64 g_mime_certificate_get_created64 (GMimeCertificate *cert);
function M.g_mime_certificate_get_created64(cert)
	return gmime.g_mime_certificate_get_created64(cert)
end
--
-- void g_mime_certificate_set_expires (GMimeCertificate *cert, time_t expires);
function M.g_mime_certificate_set_expires(cert, expires)
	gmime.g_mime_certificate_set_expires(cert, expires)
end
-- time_t g_mime_certificate_get_expires (GMimeCertificate *cert);
function M.g_mime_certificate_get_expires(cert)
	return gmime.g_mime_certificate_get_expires(cert)
end
-- gint64 g_mime_certificate_get_expires64 (GMimeCertificate *cert);
function M.g_mime_certificate_get_expires64(cert)
	return gmime.g_mime_certificate_get_expires64(cert)
end
--
-- GMimeCertificateList *g_mime_certificate_list_new (void);
function M.g_mime_certificate_list_new()
	return gmime.g_mime_certificate_list_new()
end
--
-- int g_mime_certificate_list_length (GMimeCertificateList *list);
function M.g_mime_certificate_list_length(list)
	return gmime.g_mime_certificate_list_length(list)
end
--
-- void g_mime_certificate_list_clear (GMimeCertificateList *list);
function M.g_mime_certificate_list_clear(list)
	gmime.g_mime_certificate_list_clear(list)
end
--
-- int g_mime_certificate_list_add (GMimeCertificateList *list, GMimeCertificate *cert);
function M.g_mime_certificate_list_add(list, cert)
	return gmime.g_mime_certificate_list_add(list, cert)
end
-- void g_mime_certificate_list_insert (GMimeCertificateList *list, int index, GMimeCertificate *cert);
function M.g_mime_certificate_list_insert(list, index, cert)
	gmime.g_mime_certificate_list_insert(list, index, cert)
end
-- gboolean g_mime_certificate_list_remove (GMimeCertificateList *list, GMimeCertificate *cert);
function M.g_mime_certificate_list_remove(list, cert)
	return gmime.g_mime_certificate_list_remove(list, cert)
end
-- gboolean g_mime_certificate_list_remove_at (GMimeCertificateList *list, int index);
function M.g_mime_certificate_list_remove_at(list, index)
	return gmime.g_mime_certificate_list_remove_at(list, index)
end
--
-- gboolean g_mime_certificate_list_contains (GMimeCertificateList *list, GMimeCertificate *cert);
function M.g_mime_certificate_list_contains(list, cert)
	return gmime.g_mime_certificate_list_contains(list, cert)
end
-- int g_mime_certificate_list_index_of (GMimeCertificateList *list, GMimeCertificate *cert);
function M.g_mime_certificate_list_index_of(list, cert)
	return gmime.g_mime_certificate_list_index_of(list, cert)
end
--
-- GMimeCertificate *g_mime_certificate_list_get_certificate (GMimeCertificateList *list, int index);
function M.g_mime_certificate_list_get_certificate(list, index)
	return gmime.g_mime_certificate_list_get_certificate(list, index)
end
-- void g_mime_certificate_list_set_certificate (GMimeCertificateList *list, int index, GMimeCertificate *cert);
function M.g_mime_certificate_list_set_certificate(list, index, cert)
	return gmime.g_mime_certificate_list_set_certificate(list, index, cert)
end
--
--
local function verify(sig)
	-- XXX fix this, what should we accept?
	return gmime.g_mime_signature_get_status(sig) == gmime.GMIME_SIGNATURE_STATUS_GREEN
end

local function verify_list(siglist)
	if siglist == nil or gmime.g_mime_signature_list_length(siglist) < 1 then
		return false
	end
	-- local ret = true

	for sig in sig_iterator(siglist) do
		if verify(sig) then
			return false
		end
	end
	return true
end

return M
