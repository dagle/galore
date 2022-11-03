local config = require("galore.config")
local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

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

local decrypt_flags = {
  none = gmime.DecryptFlags.None,
  export = gmime.DecryptFlags.EXPORT_SESSION_KEY,
  noverify = gmime.DecryptFlags.NO_VERIFY,
	keyserver = gmime.DecryptFlags.ENABLE_KEYSERVER_LOOKUPS,
	online = gmime.DecryptFlags.ENABLE_ONLINE_CERTIFICATE_CHECKS
}

local verify_flags = {
	none = gmime.VerifyFlags.NONE,
	keyserver = gmime.VerifyFlags.ENABLE_KEYSERVER_LOOKUPS,
	online = gmime.VerifyFlags.ENABLE_ONLINE_CERTIFICATE_CHECKS
}

local function get_decrypt_flag(flags)
	if type(flags) == "table" then
		local flag = gmime.VerifyFlags.NONE
		for _, v in ipairs(flags) do
			flag = bit.bor(flag, get_decrypt_flag(v))
		end
		return flag
	end
	if type(flags) == "string" then
		flags = flags:lower()
    return decrypt_flags[flags] or gmime.DecryptFlags.None
	end
	return gmime.VerifyFlags.NONE
end

local function get_verify_flag(flags)
	if type(flags) == "table" then
		local flag = gmime.VerifyFlags.NONE
		for _, v in ipairs(flags) do
			flag = bit.bor(flag, get_verify_flag(v))
		end
		return flag
	end
	if type(flags) == "string" then
		flags = flags:lower()
    return verify_flags[flags] or gmime.DecryptFlags.None
	end
	return gmime.VerifyFlags.NONE
end

function M.verify_signed(object)
	local keyflag = get_verify_flag(config.values.verify_flags)
	local signatures, error = object:verify(keyflag)
	if not signatures and error then
		return false
	else
		return verify_list(signatures)
	end
end

function M.decrypt_and_verify(obj, flags, key)
  -- we don't get a result or do we get either a result or an error?
	local decrypted, err = obj:decrypt(
		flags,
		key
	)

  if not decrypted then
    -- log error
    return nil, nil, nil
  end

	-- if err ~= nil then
	-- 	local str = string.format("Failed to decrypt message: %s", err)
	-- 	log.log(str, vim.log.levels.ERROR)
	-- 	return
	-- end

	local sign
	if result then
		sign = verify_list(result:get_signatures())
	end

	local new_key = result:get_session_key()

	return decrypted, sign, new_key
end

-- maybe not do these
function M.sign(ctx, obj)
	local ret, err = gmime.MultipartSigned.sign(ctx, obj, config.gpg_id)
	return ret, err
end

-- maybe not do these
function M.encrypt(ctx, obj, opts, recipients)
	local multi, err = gmime.MultipartEncrypted.encrypt(ctx, obj, opts.sign, opts.gpg_id, opts.encrypt_flags, recipients)
	return multi, err
end

return M
