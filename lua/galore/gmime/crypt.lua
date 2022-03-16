local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}

--- @param protocol string
--- @param func fun():gmime.CryptoContext
function M.crypto_context_register(protocol, func)
	gmime.g_mime_crypto_context_register(protocol, func)
end

--- @param ctx gmime.CryptoContext
--- @param func fun(gmime.CryptoContext, string, string, boolean, gmime.Stream):boolean
function M.crypto_context_set_request_password(ctx, func)
	gmime.g_mime_crypto_context_set_request_password(ctx, func)
end

--- @param protocol string
--- @return gmime.CryptoContext
function M.crypto_context_new(protocol)
	return ffi.gc(gmime.g_mime_crypto_context_new(protocol), gmime.g_object_unref)
end

--- @param ctx gmime.CryptoContext
--- @param name string
--- @return gmime.DigestAlgo
function M.crypto_context_digest_id(ctx, name)
	return gmime.g_mime_crypto_context_digest_id(ctx, name)
end

--- @param ctx gmime.CryptoContext
--- @param digest gmime.DigestAlgo
--- @return string
function M.crypto_context_digest_name(ctx, digest)
	return ffi.string(gmime.g_mime_crypto_context_digest_name(ctx, digest))
end

--- @param ctx gmime.CryptoContext
--- @return string
function M.crypto_context_get_signature_protocol(ctx)
	return ffi.string(gmime.g_mime_crypto_context_get_signature_protocol(ctx))
end

--- @param ctx gmime.CryptoContext
--- @return string
function M.crypto_context_get_encryption_protocol(ctx)
	return ffi.string(gmime.g_mime_crypto_context_get_encryption_protocol(ctx))
end

--- @param ctx gmime.CryptoContext
--- @return string
function M.crypto_context_get_key_exchange_protocol(ctx)
	return ffi.string(gmime.g_mime_crypto_context_get_key_exchange_protocol(ctx))
end

--- @param ctx gmime.CryptoContext
--- @param detach boolean
--- @param userid string
--- @param instream gmime.Stream
--- @param outstream gmime.Stream
--- @return number, gmime.Error
function M.crypto_context_sign(ctx, detach, userid, instream, outstream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_sign(ctx, detach, userid, instream, outstream, err)
	return ret, err[0]
end

--- @param ctx gmime.CryptoContext
--- @param flags gmime.VerifyFlags
--- @param instream gmime.Stream
--- @param sigstream gmime.Stream
--- @param outstream gmime.Stream
--- @return gmime.SignatureList, gmime.Error
function M.crypto_context_verify(ctx, flags, instream, sigstream, outstream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_verify(ctx, flags, instream, sigstream, outstream, err)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

--- @param ctx gmime.CryptoContext
--- @param flags gmime.EncryptFlags
--- @param recipients string[]
--- @param instream gmime.Stream
--- @param outstream gmime.Stream
--- @return number, gmime.Error
function M.crypto_context_encrypt(ctx, sign, userid, flags, recipients, instream, outstream)
	local array = gmime.g_ptr_array_sized_new(0)
	for _, rep in ipairs(recipients) do
		gmime.g_ptr_array_add(array, ffi.cast("gpointer", rep))
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_encrypt(ctx, sign, userid, flags, array, instream, outstream, err)
	gmime.g_ptr_array_free(array, false)
	return ret, err[0]
end

--- @param ctx gmime.CryptoContext
--- @param flags gmime.DecryptFlags
--- @param session_key string
--- @param istream gmime.Stream
--- @param ostream gmime.Stream
--- @return gmime.DecryptResult, gmime.Error
function M.crypto_context_decrypt(ctx, flags, session_key, istream, ostream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_decrypt(ctx, flags, session_key, istream, ostream, err)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

--- @param ctx gmime.CryptoContext
--- @param istream gmime.Stream
--- @return number, gmime.Error
function M.crypto_context_import_keys(ctx, istream)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_import_keys(ctx, istream, err)
	return ret, err[0]
end

--- @param ctx gmime.CryptoContext
--- @param keys string[]
--- @param ostream gmime.Stream
--- @return number, gmime.Error
function M.crypto_context_export_keys(ctx, keys, ostream)
	local array = ffi.new("char *[?]", #keys)
	for i, key in ipairs(keys) do
		array[i-1] = key
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_crypto_context_export_keys(ctx, array, ostream, err)
	return ret, err[0]
end

--- @return gmime.DecryptResult
function M.decrypt_result_new()
	return ffi.gc(gmime.g_mime_decrypt_result_new(), gmime.g_object_unref)
end

--- @param result gmime.DecryptResult
--- @param recipients gmime.CertificateList
function M.decrypt_result_set_recipients(result, recipients)
	gmime.g_mime_decrypt_result_set_recipients(result, recipients)
end

--- @param result gmime.DecryptResult
--- @return gmime.CertificateList
function M.decrypt_result_get_recipients(result)
	return gmime.g_mime_decrypt_result_get_recipients(result)
end

--- @param result gmime.DecryptResult
--- @param signatures gmime.SignatureList
function M.decrypt_result_set_signatures(result, signatures)
	gmime.g_mime_decrypt_result_set_signatures(result, signatures)
end

--- @param result gmime.DecryptResult
--- @return gmime.SignatureList
function M.decrypt_result_get_signatures(result)
	gmime.g_mime_decrypt_result_get_signatures(result)
end

--- @param result gmime.DecryptResult
--- @param cipher gmime.CipherAlgo
function M.decrypt_result_set_cipher(result, cipher)
	gmime.g_mime_decrypt_result_set_cipher(result, cipher)
end

--- @param result gmime.DecryptResult
--- @return gmime.CipherAlgo
function M.decrypt_result_get_cipher(result)
	gmime.g_mime_decrypt_result_get_cipher(result)
end

--- @param result gmime.DecryptResult
--- @param mdc gmime.DigestAlgo
function M.decrypt_result_set_mdc(result, mdc)
	gmime.g_mime_decrypt_result_set_mdc(result, mdc)
end

--- @param result gmime.DecryptResult
--- @return gmime.DigestAlgo
function M.decrypt_result_get_mdc(result)
	gmime.g_mime_decrypt_result_get_mdc(result)
end

--- @param result gmime.DecryptResult
--- @param session_key string
function M.decrypt_result_set_session_key(result, session_key)
	ffi.string(gmime.g_mime_decrypt_result_set_session_key(result, session_key))
end

--- @param result gmime.DecryptResult
--- @retun string
function M.decrypt_result_get_session_key(result)
	gmime.g_mime_decrypt_result_get_session_key(result)
end

--- @return gmime.AutocryptHeader
function M.autocrypt_header_new()
	return ffi.gc(gmime.g_mime_autocrypt_header_new(), gmime.g_object_unref)
end

--- @param str string
--- @return gmime.AutocryptHeader
function M.autocrypt_header_new_from_string(str)
	gmime.g_mime_autocrypt_header_new_from_string(str)
end

--- @param ah gmime.AutocryptHeader
--- @param addresss gmime.InternetAddressMailbox
function M.autocrypt_header_set_address(ah, addresss)
	gmime.g_mime_autocrypt_header_set_address(ah, addresss)
end

--- @param ah gmime.AutocryptHeader
--- @return gmime.InternetAddressMailbox
function M.autocrypt_header_get_address(ah)
	return gmime.g_mime_autocrypt_header_get_address(ah)
end

--- @param ah gmime.AutocryptHeader
--- @param address string
function M.autocrypt_header_set_address_from_string(ah, address)
	gmime.g_mime_autocrypt_header_set_address_from_string(ah, address)
end

--- @param ah gmime.AutocryptHeader
--- @return string
function M.autocrypt_header_get_address_as_string(ah)
	return ffi.string(gmime.g_mime_autocrypt_header_get_address_as_string(ah))
end

--- @param ah gmime.AutocryptHeader
--- @param pref gmime.AutocryptPreferEncrypt
function M.autocrypt_header_set_prefer_encrypt(ah, pref)
	gmime.g_mime_autocrypt_header_set_prefer_encrypt(ah, pref)
end

--- @param ah gmime.AutocryptHeader
--- @return gmime.AutocryptPreferEncrypt
function M.autocrypt_header_get_prefer_encrypt(ah)
	return gmime.g_mime_autocrypt_header_get_prefer_encrypt(ah)
end

--
-- void g_mime_autocrypt_header_set_keydata (GMimeAutocryptHeader *ah, GBytes *data);
--- XXX
function M.autocrypt_header_set_keydata()
	gmime.g_mime_autocrypt_header_set_keydata()
end
--- XXX
-- GBytes *g_mime_autocrypt_header_get_keydata (GMimeAutocryptHeader *ah);
function M.autocrypt_header_get_keydata()
	gmime.g_mime_autocrypt_header_get_keydata()
end

--- @param ah gmime.AutocryptHeader
--- @param date number
function M.autocrypt_header_set_effective_date(ah, date)
	local gdate = gmime.g_date_time_new_from_unix_local(date)
	gmime.g_mime_autocrypt_header_set_effective_date(ah, gdate)
	gmime.g_date_time_unref(gdate)
end

--- @param ah gmime.AutocryptHeader
--- @return number
function M.autocrypt_header_get_effective_date(ah)
	local gdate = gmime.g_mime_autocrypt_header_get_effective_date(ah)
	local date = gmime.g_date_time_to_unix(gdate)
	gmime.g_date_time_unref(gdate)
	return tonumber(date)
end

--- @param ah gmime.AutocryptHeader
--- @param gossip boolean
--- @return string
function M.autocrypt_header_to_string(ah, gossip)
	local mem = gmime.g_mime_autocrypt_header_to_string(ah, gossip)
	return convert.strdup(mem)
end

--- @param ah gmime.AutocryptHeader
--- @return boolean
function M.autocrypt_header_is_complete(ah)
	return gmime.g_mime_autocrypt_header_is_complete(ah) ~= 0
end

--- @param ah1 gmime.AutocryptHeader
--- @param ah2 gmime.AutocryptHeader
--- @return number
function M.autocrypt_header_compare(ah1, ah2)
	return gmime.g_mime_autocrypt_header_compare(ah1, ah2)
end

--- @param dst gmime.AutocryptHeader
--- @param src gmime.AutocryptHeader
function M.autocrypt_header_clone(dst, src)
	gmime.g_mime_autocrypt_header_clone(dst, src)
end

--- @return gmime.AutocryptHeaderList
function M.autocrypt_header_list_new()
	return ffi.gc(gmime.g_mime_autocrypt_header_list_new(), gmime.g_object_unref)
end

--- @param list gmime.AutocryptHeaderList
--- @param addresses gmime.InternetAddressList
--- @return number
function M.autocrypt_header_list_add_missing_addresses(list, addresses)
	return gmime.g_mime_autocrypt_header_list_add_missing_addresses(list, addresses)
end

--- @param list gmime.AutocryptHeaderList
--- @param header gmime.AutocryptHeader
function M.autocrypt_header_list_add(list, header)
	gmime.g_mime_autocrypt_header_list_add(list, header)
end

--- @param list list gmime.AutocryptHeaderList
--- @return number
function M.autocrypt_header_list_get_count(list)
	return gmime.g_mime_autocrypt_header_list_get_count(list)
end

--- @param list gmime.AutocryptHeaderList
--- @param index number
--- @return gmime.AutocryptHeader
function M.autocrypt_header_list_get_header_at(list, index)
	return gmime.g_mime_autocrypt_header_list_get_header_at(list, index)
end

--- @param list gmime.AutocryptHeaderList
--- @param mb gmime.InternetAddressMailbox
--- @return gmime.AutocryptHeader
function M.autocrypt_header_list_get_header_for_address(list, mb)
	return gmime.g_mime_autocrypt_header_list_get_header_for_address(list, mb)
end

--- @param list gmime.AutocryptHeaderList
function M.autocrypt_header_list_remove_incomplete(list)
	gmime.g_mime_autocrypt_header_list_remove_incomplete(list)
end

--- @return gmime.Signature
function M.signature_new()
	return ffi.gc(gmime.g_mime_signature_new(), gmime.g_object_unref)
end

--- @param sig gmime.Signature
--- @param cert gmime.Certificate
function M.signature_set_certificate(sig, cert)
	gmime.g_mime_signature_set_certificate(sig, cert)
end

--- @param sig gmime.Signature
--- @return gmime.Certificate
function M.signature_get_certificate(sig)
	return gmime.g_mime_signature_get_certificate(sig)
end

--- @param sig gmime.Signature
--- @param status gmime.SignatureStatus
function M.signature_set_status(sig, status)
	gmime.g_mime_signature_set_status(sig, status)
end

--- @param sig gmime.Signature
--- @return gmime.SignatureStatus
function M.signature_get_status(sig)
	return gmime.g_mime_signature_get_status(sig)
end

--- @param sig gmime.Signature
--- @param created number
function M.signature_set_created(sig, created)
	gmime.g_mime_signature_set_created(sig, created)
end

--- @param sig gmime.Signature
--- @return number
function M.signature_get_created(sig)
	return tonumber(gmime.g_mime_signature_get_created(sig))
end

--- @param sig gmime.Signature
--- @return number
function M.signature_get_created64(sig)
	return tonumber(gmime.g_mime_signature_get_created64(sig))
end

--- @param sig gmime.Signature
--- @param expire number
function M.signature_set_expires(sig, expire)
	gmime.g_mime_signature_set_expires(sig, expire)
end

--- @param sig gmime.Signature
--- @return number
function M.signature_get_expires(sig)
	return tonumber(gmime.g_mime_signature_get_expires(sig))
end

--- @param sig gmime.Signature
--- @return number
function M.signature_get_expires64(sig)
	return tonumber(gmime.g_mime_signature_get_expires64(sig))
end

--- @return gmime.SignatureList
function M.signature_list_new()
	return ffi.gc(gmime.g_mime_signature_list_new(), gmime.g_object_unref)
end

--- @param list gmime.SignatureList
--- @return number
function M.signature_list_length(list)
	return gmime.g_mime_signature_list_length(list)
end

--- @param list gmime.SignatureList
function M.signature_list_clear(list)
	gmime.g_mime_signature_list_clear(list)
end

--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return number
function M.signature_list_add(list, sig)
	return gmime.g_mime_signature_list_add(list, sig)
end

--- @param list gmime.SignatureList
--- @param index number
--- @param sig gmime.Signature
function M.signature_list_insert(list, index, sig)
	gmime.g_mime_signature_list_insert(list, index, sig)
end

--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return boolean
function M.signature_list_remove(list, sig)
	return gmime.g_mime_signature_list_remove(list, sig)
end

--- @param list gmime.SignatureList
--- @param index number
--- @return boolean
function M.signature_list_remove_at(list, index)
	return gmime.g_mime_signature_list_remove_at(list, index) ~= 0
end

--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return boolean
function M.signature_list_contains(list, sig)
	return gmime.g_mime_signature_list_contains(list, sig) ~= 0
end

--- @param list gmime.SignatureList
--- @param sig gmime.Signature
--- @return number
function M.signature_list_index_of(list, sig)
	return gmime.g_mime_signature_list_index_of(list, sig)
end

--- @param list gmime.SignatureList
--- @param index number
--- @return gmime.Signature
function M.signature_list_get_signature(list, index)
	return gmime.g_mime_signature_list_get_signature(list, index)
end

--- @return gmime.CryptoContext
function M.pkcs7_context_new(list, sig)
	return ffi.gc(gmime.g_mime_pkcs7_context_new(list, sig), gmime.g_object_unref)
end

--- @param list gmime.SignatureList
--- @param index number
--- @param sig gmime.Signature
function M.signature_list_set_signature(list, index, sig)
	gmime.g_mime_signature_list_set_signature(list, index, sig)
end

--- @param type gmime.SecureMimeType
--- @return gmime.ApplicationPkcs7Mime
function M.application_pkcs7_mime_new(type)
	return ffi.gc(gmime.g_mime_application_pkcs7_mime_new(type), gmime.g_object_unref)
end

--- @param pkcs7_mime gmime.ApplicationPkcs7Mime
--- @return gmime.SecureMimeType
function M.application_pkcs7_mime_get_smime_type(pkcs7_mime)
	return gmime.g_mime_application_pkcs7_mime_get_smime_type(pkcs7_mime)
end

--- @param entity gmime.MimeObject
--- @param flags gmime.EncryptFlags
--- @param recipients string[]
--- @return gmime.ApplicationPkcs7Mime, gmime.Error
function M.application_pkcs7_mime_encrypt(entity, flags, recipients)
	local array = gmime.g_ptr_array_sized_new(0)
	for _, rep in ipairs(recipients) do
		gmime.g_ptr_array_add(array, ffi.cast("gpointer", rep))
	end
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_encrypt(entity, flags, array, err)
	gmime.g_ptr_array_free(array, false)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

--- @param pkcs7_mime gmime.ApplicationPkcs7Mime
--- @param flags gmime.DecryptFlags
--- @param session_key string
--- @return boolean, gmime.DecryptResult, gmime.Error
function M.application_pkcs7_mime_decrypt(pkcs7_mime, flags, session_key)
	local err = ffi.new("GError*[1]")
	local result = ffi.new("GMimeDecryptResult*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_decrypt(pkcs7_mime, flags, session_key, result, err)
	return ret ~= 0, result[0], err[0]
end

--- @param entity gmime.MimeObject
--- @param userid string
--- @return gmime.ApplicationPkcs7Mime, gmime.Error
function M.application_pkcs7_mime_sign(entity, userid)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_sign(entity, userid, err)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

--- @param pkcs7_mime gmime.ApplicationPkcs7Mime
--- @param flags gmime.VerifyFlags
--- @return gmime.SignatureList, gmime.MimeObject, gmime.Error
function M.application_pkcs7_mime_verify(pkcs7_mime, flags)
	local err = ffi.new("GError*[1]")
	local objects = ffi.new("GMimeObject*[1]")
	local ret = gmime.g_mime_application_pkcs7_mime_verify(pkcs7_mime, flags, objects, err)
	return ffi.gc(ret, gmime.g_object_unref), objects[0], err[0]
end

--- @return gmime.CryptoContext
function M.gpg_context_new()
	return ffi.gc(gmime.g_mime_gpg_context_new(), gmime.g_object_unref)
end

--- @return gmime.Certificate
function M.certificate_new()
	return ffi.gc(gmime.g_mime_certificate_new(), gmime.g_object_unref)
end

--- @param cert gmime.Certificate
--- @param trust gmime.Trust
function M.certificate_set_trust(cert, trust)
	gmime.g_mime_certificate_set_trust(cert, trust)
end

--- @param cert gmime.Certificate
--- @return gmime.Trust
function M.certificate_get_trust(cert)
	return gmime.g_mime_certificate_get_trust(cert)
end

--- @param cert gmime.Certificate
--- @param algo gmime.PubKeyAlgo
function M.certificate_set_pubkey_algo(cert, algo)
	gmime.g_mime_certificate_set_pubkey_algo(cert, algo)
end

--- @param cert gmime.Certificate
--- @return gmime.PubKeyAlgo
function M.certificate_get_pubkey_algo(cert)
	return gmime.g_mime_certificate_get_pubkey_algo(cert)
end

--- @param cert gmime.Certificate
--- @param algo gmime.DigestAlgo
function M.certificate_set_digest_algo(cert, algo)
	return gmime.g_mime_certificate_set_digest_algo(cert, algo)
end

--- @param cert gmime.Certificate
--- @return gmime.DigestAlgo
function M.certificate_get_digest_algo(cert)
	return gmime.g_mime_certificate_get_digest_algo(cert)
end

--- @param cert gmime.Certificate
--- @param issuer string
function M.certificate_set_issuer_serial(cert, issuer)
	gmime.g_mime_certificate_set_issuer_serial(cert, issuer)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_issuer_serial(cert)
	return ffi.string(gmime.g_mime_certificate_get_issuer_serial(cert))
end

--- @param cert gmime.Certificate
--- @param issuer string
function M.certificate_set_issuer_name(cert, issuer)
	gmime.g_mime_certificate_set_issuer_name(cert, issuer)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_issuer_name(cert)
	gmime.g_mime_certificate_get_issuer_name(cert)
end

--- @param cert gmime.Certificate
--- @param fingerprint string
function M.certificate_set_fingerprint(cert, fingerprint)
	gmime.g_mime_certificate_set_fingerprint(cert, fingerprint)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_fingerprint(cert)
	return ffi.string(gmime.g_mime_certificate_get_fingerprint(cert))
end

--- @param cert gmime.Certificate
--- @param keyid string
function M.certificate_set_key_id(cert, keyid)
	gmime.g_mime_certificate_set_key_id(cert, keyid)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_key_id(cert)
	return ffi.string(gmime.g_mime_certificate_get_key_id(cert))
end

--- @param cert gmime.Certificate
--- @param email string
function M.certificate_set_email(cert, email)
	gmime.g_mime_certificate_set_email(cert, email)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_email(cert)
	return ffi.string(gmime.g_mime_certificate_get_email(cert))
end

--- @param cert gmime.Certificate
--- @param name string
function M.certificate_set_name(cert, name)
	gmime.g_mime_certificate_set_name(cert, name)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_name(cert)
	return ffi.string(gmime.g_mime_certificate_get_name(cert))
end

--- @param cert gmime.Certificate
--- @param userid string
function M.certificate_set_user_id(cert, userid)
	gmime.g_mime_certificate_set_user_id(cert, userid)
end

--- @param cert gmime.Certificate
--- @return string
function M.certificate_get_user_id(cert)
	gmime.g_mime_certificate_get_user_id(cert)
end

--- @param cert gmime.Certificate
--- @param validity gmime.Validity
function M.certificate_set_id_validity(cert, validity)
	gmime.g_mime_certificate_set_id_validity(cert, validity)
end

--- @param cert gmime.Certificate
--- @return gmime.Validity
function M.certificate_get_id_validity(cert)
	return gmime.g_mime_certificate_get_id_validity(cert)
end

--- @param cert gmime.Certificate
--- @param created number
function M.certificate_set_created(cert, created)
	gmime.g_mime_certificate_set_created(cert, created)
end

--- @param cert gmime.Certificate
--- @return number
function M.certificate_get_created(cert)
	return tonumber(gmime.g_mime_certificate_get_created(cert))
end

--- @param cert gmime.Certificate
--- @return number
function M.certificate_get_created64(cert)
	return tonumber(gmime.g_mime_certificate_get_created64(cert))
end

--- @param cert gmime.Certificate
--- @param expires number
function M.certificate_set_expires(cert, expires)
	gmime.g_mime_certificate_set_expires(cert, expires)
end

--- @param cert gmime.Certificate
--- @return number
function M.certificate_get_expires(cert)
	return tonumber(gmime.g_mime_certificate_get_expires(cert))
end

--- @param cert gmime.Certificate
--- @return number
function M.certificate_get_expires64(cert)
	return tonumber(gmime.g_mime_certificate_get_expires64(cert))
end

--- @return gmime.CertificateList
function M.certificate_list_new()
	return ffi.gc(gmime.g_mime_certificate_list_new(), gmime.g_object_unref)
end

--- @param list gmime.CertificateList
--- @return number
function M.certificate_list_length(list)
	return gmime.g_mime_certificate_list_length(list)
end

--- @param list gmime.CertificateList
function M.certificate_list_clear(list)
	gmime.g_mime_certificate_list_clear(list)
end

--- @param list gmime.CertificateList
--- @param cert gmime.Certificate
--- @return number
function M.certificate_list_add(list, cert)
	return gmime.g_mime_certificate_list_add(list, cert)
end

--- @param list gmime.CertificateList
--- @param index number
--- @param cert gmime.Certificate
function M.certificate_list_insert(list, index, cert)
	gmime.g_mime_certificate_list_insert(list, index, cert)
end

--- @param list gmime.CertificateList
--- @param cert gmime.Certificate
--- @return boolean
function M.certificate_list_remove(list, cert)
	return gmime.g_mime_certificate_list_remove(list, cert) ~= 0
end

--- @param list gmime.CertificateList
--- @param index number
--- @return boolean
function M.certificate_list_remove_at(list, index)
	return gmime.g_mime_certificate_list_remove_at(list, index) ~= 0
end

--- @param list gmime.CertificateList
--- @param cert gmime.Certificate
--- @return boolean
function M.certificate_list_contains(list, cert)
	return gmime.g_mime_certificate_list_contains(list, cert) ~= 0
end

--- @param list gmime.CertificateList
--- @param cert gmime.Certificate
--- @return number
function M.certificate_list_index_of(list, cert)
	return gmime.g_mime_certificate_list_index_of(list, cert)
end

--- @param list gmime.CertificateList
--- @param index number
--- @return gmime.Certificate
function M.certificate_list_get_certificate(list, index)
	return gmime.g_mime_certificate_list_get_certificate(list, index)
end

--- @param list gmime.CertificateList
--- @param index number
--- @param cert gmime.Certificate
function M.certificate_list_set_certificate(list, index, cert)
	return gmime.g_mime_certificate_list_set_certificate(list, index, cert)
end


function M.sig_iterator(siglist)
	local i = gmime.g_mime_signature_list_length(siglist)
	local j = 0
	return function()
		if j < i then
			local sig = gmime.g_mime_signature_list_get_signature(siglist, j)
			j = j + 1
			return sig
		end
	end
end

local function verify(sig)
	-- XXX fix this, what should we accept?
	return gmime.g_mime_signature_get_status(sig) == gmime.GMIME_SIGNATURE_STATUS_GREEN
end

local function verify_list(siglist)
	if siglist == nil or gmime.g_mime_signature_list_length(siglist) < 1 then
		return false
	end

	for sig in M.sig_iterator(siglist) do
		if verify(sig) then
			return true
		end
	end
	return false
end

-- @param recipients An array of recipient key ids and/or email addresses
function M.encrypt(ctx, part, id, recipients)
	-- convert a table to a C array
	-- we need to free this
	local gp_array = gmime.g_ptr_array_sized_new(#recipients)
	for _, rep in pairs(recipients) do
		gmime.g_ptr_array_add(gp_array, ffi.cast("gpointer", rep))
	end
	local error = ffi.new("GError*[1]")
	local obj = ffi.cast("GMimeObject *", part)
	local ret = gmime.g_mime_multipart_encrypted_encrypt(
		ctx,
		obj,
		true,
		id,
		gmime.GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS,
		gp_array,
		error
	)
	return ret, error
	-- return ret, ffi.string(galore.print_error(error[0]))
end

function M.sign(ctx, part, id)
	local error = ffi.new("GError*[1]")
	local obj = ffi.cast("GMimeObject *", part)
	local ret = gmime.g_mime_multipart_signed_sign(ctx, obj, id, error)
	return ret
	-- return ret, ffi.string(galore.print_error(error[0]))
end

function M.verify_signed(part)
	local signed = ffi.cast("GMimeMultipartSigned *", part)
	local error = ffi.new("GError*[1]")
	local ret

	local signatures = gmime.g_mime_multipart_signed_verify(
		signed,
		gmime.GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS,
		error
	)
	if not signatures then
		-- XXX convert this into an error
		print("Failed to verify signed part: " .. error.message)
	else
		ret = verify_list(signatures)
	end
	return ret
end

function M.decrypt_and_verify(part)
	local encrypted = ffi.cast("GMimeMultipartEncrypted *", part)
	local error = ffi.new("GError*[1]")
	local res = ffi.new("GMimeDecryptResult*[1]")
	-- do we need to configure a session key?
	local session = nil
	local decrypted = gmime.g_mime_multipart_encrypted_decrypt(
		encrypted,
		gmime.GMIME_DECRYPT_ENABLE_KEYSERVER_LOOKUPS,
		session,
		res,
		error
	)

	local sign
	if res then
		sign = verify_list(gmime.g_mime_decrypt_result_get_signatures(res[0]))
	end

	return decrypted, sign
end

-- function M.multipart_get_count(multipart)
-- 	return galore.g_mime_multipart_get_count(multipart)
-- end
-- function M.multipart_get_part(multipart, index)
-- 	return galore.g_mime_multipart_get_part(multipart, index)
-- end
--



return M
