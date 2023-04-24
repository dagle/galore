local config = require("galore.config")
local log = require("galore.log")
local gmime = require("galore.gmime")

local M = {}

local function verify_list(siglist)
	if siglist == nil then
		return false
	end

	local sigs = siglist:length(siglist) > 0
	-- P(siglist:length())
	for i = 0, siglist:length() do
		local sig = siglist:get_signature(i)
		if sig ~= nil then
			local test = config.values.validate_key(sig:get_status())
			sigs = sigs and test
		end
	end
	return sigs
end

function M.verify_signed(object)
	local signatures, error = object:verify(gmime.VerifyFlags(config.values.verify_flags))
	if not signatures and error then
		return false
	else
		return verify_list(signatures)
	end
end

function M.decrypt_and_verify(obj, flags, key)
  -- we don't get a result or do we get either a result or an error?
	local decrypted, result, err = obj:decrypt(
		flags,
		key
	)

	if not decrypted or err ~= nil then
		local str = string.format("Failed to decrypt message: %s", err)
		log.log(str, vim.log.levels.ERROR)
		return
	end

	local sign
	if result then
		sign = verify_list(result:get_signatures())
	end

	local new_key = result:get_session_key()

	return decrypted, sign, new_key
end

-- maybe not do these
function M.sign(ctx, obj, pgp_id)
	local ret, err = gmime.MultipartSigned.sign(ctx, obj, pgp_id)
	return ret, err
end

-- maybe not do these
function M.encrypt(ctx, obj, opts, recipients)
	local multi, err = gmime.MultipartEncrypted.encrypt(ctx, obj, opts.sign, opts.gpg_id, opts.encrypt_flags, recipients)
	return multi, err
end

return M
