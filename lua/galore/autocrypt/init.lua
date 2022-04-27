local ok, sqlite = pcall(require, "sqlite.db")
if not ok then
	return
end

local gc = require("galore.gmime.crypt")

local tbl = require "sqlite.tbl"

local M = {}
local uri = vim.fn.stdpath('data') .. "/autocrypt.db"

-- defaults?
local account = tbl("account", {
	email_addr = {type = "text", required = true, primary = true},
	keyid = "text",
	keydata = "text",
	prefer_encrypt = {"number", default = 1},
	enabled = {"number", default = 0},
})

local peer = tbl("peer", {
	email_addr = {type = "text", required = true, primary = true},
	last_seen = "date",
	autocrypt_timestamp = "date",
	keyid = "text",
	keydata = "text",
	prefer_encrypt = "number",
	gossip_timestamp = "date",
	gossip_keyid = "text",
	gossip_keydata = "text";
})

local peer_history = tbl("peer_history", {
	email_addr = {type = "text", required = true },
	msgid = "text",
	timestamp = "number",
	keydata = "text",
})

local gossip_history = tbl("gossip_history", {
	peer_addr = {type = "text", required = true},
	sender_addr = {type = "text", required = true},
})

local autocrypt = tbl("autocrypt", {
	addr = {type = "text", required = true, primary = true},
	last_seen = "date",
	timestamp = "date",
	keyid = "text",
	keydata = "text",
	expires = "date",
	prefer_encrypt = {"number", default = 1},
	enabled = {"number", default = 0},
})

local db = sqlite {
  uri = uri,
  autocrypt = autocrypt,
}

--- add history
function M.update(ah, sent)
	local addr = gc.autocrypt_header_get_address_as_string(ah)
	local seen = os.time()
	local timestamp = gc.autocrypt_header_get_effective_date(ah)
	--- get keyid and keydata?
	local key = gc.autocrypt_header_get_keydata(ah)
	--- get id from key somehow
	local keyid
	local expires
	--- get expire date
	local prefer = gc.autocrypt_header_get_prefer_encrypt(ah)

	local row = autocrypt:where { addr = addr }
	if not row then
		local new_row = {
			addr = addr,
			last_seen = seen,
			timestamp = timestamp,
			keyid = keyid,
			keydata = key,
			expires = expires,
			prefer_encrypt = prefer,
			enabled = 1,
		}
		autocrypt:insert(new_row)
		--- insert the key
	else
		--- XXX what time should we compare to? timestamp?
		if row.timestamp >= sent then
			return
		end
		if row.last_seen < sent then
			autocrypt:update {
				where = { addr = addr },
				set = {
					last_seen = seen,
					timestamp = timestamp,
				}
			}
			if row.key ~= key then
				--- update the key
			end
		end
	end
end

----
function M.update_gossip(ah,sent)
	local addr = gc.autocrypt_header_get_address_as_string(ah)
	local seen = os.time()
	local timestamp = gc.autocrypt_header_get_effective_date(ah)
	--- get keyid and keydata?
	local key = gc.autocrypt_header_get_keydata(ah)
	--- get id from key somehow
	local keyid
	local expires
	--- get expire date
	local prefer = gc.autocrypt_header_get_prefer_encrypt(ah)

	local row = autocrypt:where { addr = addr }
	if not row then
		local new_row = {
			addr = addr,
			last_seen = seen,
			timestamp = timestamp,
			keyid = keyid,
			keydata = key,
			expires = expires,
			prefer_encrypt = prefer,
			enabled = 1,
		}
		autocrypt:insert(new_row)
		--- insert the key
	else
		--- XXX what time should we compare to? timestamp?
		if row.timestamp >= sent then
			return
		end
		if row.last_seen < sent then
			autocrypt:update {
				where = { addr = addr },
				set = {
					last_seen = seen,
					timestamp = timestamp,
				}
			}
			if row.key ~= key then
				--- update the key
			end
		end
	end
end

---
function M.init_key(copy)
end

return M
