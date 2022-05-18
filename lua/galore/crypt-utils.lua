local ge = require("galore.gmime.crypt")
local gp = require("galore.gmime.parts")
local gmime = require("galore.gmime.gmime_ffi")
local config = require("galore.config")
local runtime = require("galore.runtime")
local ffi = require("ffi")

local M = {}

local function verify_list(siglist)
	if siglist == nil then
		return false
	end

	local sigs = ge.signature_list_length(siglist) > 0
	for sig in ge.sig_iterator(siglist) do
		local test = config.values.validate_key(ge.signature_get_status(sig))
		sigs = sigs and test
	end
	return sigs
end

--- @param obj gmime.MultipartSigned
--- @return boolean
function M.verify_signed(obj)
	local mps = ffi.cast("GMimeMultipartSigned *", obj)
	local signatures, error = gp.multipart_signed_verify(mps, config.values.verify_flags)
	if not signatures and error then
		return false
	else
		return verify_list(signatures)
	end
end

function M.sign(ctx, obj)
	local ret, err = gmime.g_mime_multipart_signed_sign(ctx, obj, config.gpg_id, error)
	return ret, err
end

function M.encrypt(ctx, part, recipients)
	local multi, err = gp.multipart_encrypted_encrypt(ctx, part, true, config.gpg_id, config.values.encrypt_flags, recipients)
	return multi, err
end

function M.decrypt_and_verify(obj, passfun, key)
	local encrypted = ffi.cast("GMimeMultipartEncrypted *", obj)
	local decrypted, res, err = gp.multipart_encrypted_decrypt_pass(
		encrypted,
		config.values.decrypt_flags,
		passfun,
		key
	)

	if err ~= nil then
		vim.notify("Failed to decrypt message", 3)
		return
	end

	local sign
	if res then
		sign = verify_list(gmime.g_mime_decrypt_result_get_signatures(res))
	end

	--- or should we just save the ctx, do we need to update the key? I don't know gpg
	runtime.gpg_session_key = ge.decrypt_result_get_session_key(res)

	return decrypted, sign
end

return M
