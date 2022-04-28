local ok, sqlite = pcall(require, "sqlite.db")
if not ok then
	return
end


local gc = require("galore.gmime.crypt")

local tbl = require "sqlite.tbl"

local M = {}
local uri = vim.fn.stdpath('data') .. "/autocrypt.db"

-- defaults?
local peer = tbl("peer", {
	addr = {type = "text", required = true, primary = true},
	last_seen = "date",
	timestamp = "date",
	keyid = "text",
	keydata = "text",
	prefer_encrypt = {"number", default = 0},
	-- expires = expires,
	-- gossip_timestamp = "date",
	-- gossip_keyid = "text",
	-- gossip_keydata = "text";
})

local account = tbl("account", {
	addr = {type = "text", required = true, primary = true},
	enabled = "number",
	secret_key = "text",
	public_key = "text",
	prefer = "number"
	-- enabled
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

local db = sqlite {
  uri = uri,
  peer = peer,
  account = account,
}

--- add history
function M.update(ah)
	local addr = gc.autocrypt_header_get_address_as_string(ah)
	-- local seen = os.time()
	local timestamp = gc.autocrypt_header_get_effective_date(ah)
	--- get keyid and keydata?
	local key = gc.autocrypt_header_get_keydata(ah)
	--- get id from key somehow
	local keyid
	-- local expires
	--- get expire date
	local prefer = gc.autocrypt_header_get_prefer_encrypt(ah)

	local row = peer:where { addr = addr }
	if not row then
		local new_row = {
			addr = addr,
			last_seen = timestamp,
			timestamp = timestamp,
			keyid = keyid,
			keydata = key,
			-- expires = expires,
			prefer_encrypt = prefer,
			enabled = 1,
		}
		peer:insert(new_row)
	else
		--- we have a newer message in the db
		--- maybe compare timestamp and not sent?
		if row.timestamp >= timestamp then
			return
		else
			peer:update {
				where = { addr = addr },
				set = {
					last_seen = math.max(timestamp, row.last_seen),
					timestamp = timestamp,
					keyid = keyid,
					keydata = key,
					prefer_encrypt = prefer,
				}
			}
			if row.key ~= key then
				--- update the keyring
			end
		end
	end
end

-- if the message doesn't contain a autocrypt header, we just update the seen
function M.update_seen(addr, sent)
	local row = peer:where { addr = addr }
	if not row then
		return
	end
	if row.timestamp >= sent then
		return
	elseif row.last_seen < sent then
		peer:update {
			where = {addr = addr },
			set = {
				last_seen = math.max(row.last_seen, sent),
			}
		}
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

local function make_keys(addr, import)
	--- if import is set, we try to import a key from gpg
	--- if not, we just generate a new pair of keys
end

function M.make_account()
	local addr
	vim.input({prompt="Email address: "}, on_confirm: any)
	local private, public = make_keys()
	M.insert_account(addr, true, public, private, true)
end

--- XXX move
local function c_bool(bool)
	return bool and 1 or 0
end

function M.insert_account(addr, enabled, public_key, private_key, prefer)
	local row = account:where { addr = addr }
	if row ~= nil then
		vim.notify("Autocrypt account already exist")
		return
	end
	account:insert({
		addr=addr,
		enabled=c_bool(enabled),
		public=public_key,
		private=private_key,
		prefer=c_bool(prefer),
	})
end

function M.update_account(addr, fields)
end

function M.export_private_key(addr)
end

function M.export_public_key(addr)
end

function M.update_key(addr, force)
	local row = account:where { addr = addr}
	if row == nil then
		return
	end
	if expired(row.public) or force then
		local private, public = make_keys(addr)
		account:update{
			where = {addr = addr},
			set = {
				private = private,
				public = public,
			}
		}
	end
end

function M.delete_account(addr)
	account:remove { addr = addr}
end

function M.status()
	--- show accounts names, enabled, public(short), prefer for all keys.
	--- show the number of keys
end

return M
