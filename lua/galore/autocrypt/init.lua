--- Because of the limitations of gpg, we are "forced" to do this.

local ok, sqlite = pcall(require, "sqlite.db")
if not ok then
	return
end

local gc = require("galore.gmime.crypt")
local gs = require("galore.gmime.stream")
local gcu = require("galore.crypt-utils")
local runtime = require("galore.runtime")
local Job = require("plenary.job")

local tbl = require "sqlite.tbl"

local M = {}
local uri = runtime.runtime_dir() .. "/autocrypt"
local db_path = uri .. "/db.db"
local keyring_path = uri

local account = tbl("account", {
	addr = {type = "text", required = true, primary = true},
	enabled = "number",
	secret_key = "text",
	public_key = "text",
	prefer = "number"
})

-- defaults?
-- maybe keydata should be blob?
local peer = tbl("peer", {
	addr = {type = "text", required = true, primary = true},
	--- from account?
	--- user agent?
	last_seen = "date",
	timestamp = "date",
	keydata = "blob",
	prefer = {"number", default = 0},
})

local gossip = tbl("gossip", {
	addr = "text",
	from = "text",
	timestamp = "date",
	keydata = "blob",
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
  uri = db_path,
  peer = peer,
  account = account,
  gossip = gossip,
}

local function create_ctx()
	return ffi.gc(gmime.au_contex_new(), gmime.gpgme_release)
end

function M.with_ctx(func)
	local ctx = create_ctx()
	func(ctx)
end

function M.au_contex_new()
	return create_ctx()
end

--- add history?
function M.update(ah)
	local addr = gc.autocrypt_header_get_address_as_string(ah)
	local timestamp = gc.autocrypt_header_get_effective_date(ah)
	local key = gc.autocrypt_header_get_keydata(ah)
	local prefer = gc.autocrypt_header_get_prefer_encrypt(ah)

	local row = peer:where { addr = addr }
	if not row then
		local new_row = {
			addr = addr,
			timestamp = timestamp,
			keydata = key,
			prefer = prefer,
			enabled = 1,
		}
		peer:insert(new_row)
	else
		--- we have a newer message in the db
		--- maybe compare timestamp and not sent?
		if row.timestamp >= timestamp then
			return
		end
		peer:update {
			where = { addr = addr },
			set = {
				last_seen = math.max(timestamp, row.last_seen),
				timestamp = timestamp,
				keydata = key,
				prefer_encrypt = prefer,
			}
		}
		if key ~= row.key then
			--- XXX inplement string_streamer
			local stream = gs.string_streamer(key)
			M.with_ctx(function (ctx)
				gc.crypto_context_import_keys(ctx, stream)
			end)
		end
	end
end

-- if the message doesn't contain a autocrypt header, we just update the seen
function M.update_seen(addr, date)
	local row = peer:where { addr = addr }
	if not row then
		return
	end
	if row.timestamp >= date then
		return
	elseif row.last_seen < date then
		peer:update {
			where = {addr = addr },
			set = {
				last_seen = math.max(row.last_seen, date),
			}
		}
	end
end

---
function M.update_gossip(from, ahlist)
	for ah in gc.autocrypt_header_list_iter(ahlist) do
		local addr = gc.autocrypt_header_get_address_as_string(ah)
		local timestamp = gc.autocrypt_header_get_effective_date(ah)
		local key = gc.autocrypt_header_get_keydata(ah)

		local row = gossip:where { addr = addr }
		if not row then
			local new_row = {
				addr = addr,
				from = from,
				timestamp = timestamp,
				keydata = key,
			}
			gossip:insert(new_row)
		else
			if row.timestamp >= timestamp then
				return
			end
			gossip:update {
				where = { addr = addr },
				set = {
					addr = addr,
					from = from,
					timestamp = timestamp,
					keydata = key,
				}
			}
			if key ~= row.key then
				--- XXX inplement string_streamer
				local stream = gs.string_streamer(key)
				M.with_ctx(function (ctx)
					gc.crypto_context_import_keys(ctx, stream)
				end)
			end
		end
	end
end

local function createkey(path, email, expire)
	local spec = table.concat({
		"Key-Type: RSA",
		"Key-Length: 3072",
		"Key-Usage: sign",
		"Subkey-Type: RSA",
		"Subkey-Length: 3072",
		"Subkey-Usage: encrypt",
		"Name-Email: " + email,
		"Expire-Date: " + expire,
		"%commit"
	}, "\n")
	Job:new({
		command = "gpg",
		args = {"--batch", "--homedir", path, "--gen-key", spec},
		on_exit = function (_, _)
		end,
	}):sync()
end

local function make_key(addr, import)
	--- if import is set, we try to import a key from gpg
	--- if not, we just generate a new pair of keys
	local key
	--- XXX
	if import then
		key = getkey(addr)
		if not key then
			vim.notify("tried to import key from gpg but couldn't find one", vim.log.levels.ERROR)
			return
		end
		-- check that the key is "ed25519", if not, we won't allow it
	else
		local expire -- 3/6 months?
		key = createkey(keyring_path, addr, expire)
	end
	account:insert({
		addr = addr,
		enabled = 1,
		key = key,
		prefer = 1,
	})
	return key
end

function M.make_account(import)
	local addr
	vim.ui.input({prompt="Email address: "}, function (input)
		if input then
			make_key(addr, import)
		end
	end)
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
	account:update {
		where = { addr = addr},
		set = fields
	}
end

function M.decrypt(object)
	gc.crypto_context_register("application/pgp-signature", M.ctx)
	gc.crypto_context_register ("application/pgp-encrypted", M.ctx)
	local de_part, verified = gcu.decrypt_and_verify(object, runtime.get_password)

	--- maybe we shouldn't call the lua function but the ffi?
	gc.crypto_context_register ("application/pgp-signature", gc.gpg_context_new)
	gc.crypto_context_register ("application/pgp-encrypted", gc.gpg_context_new)
	return de_part, verified
end

--- Make a setup message, so we can export all keys to another mua
--- Export all accounts
--- Export all keys
--- Export all gossip
--- In an email
--- @return string, gmime.Message
function M.setup_create()
end

--- Import keys from a message
--- Import all accounts
--- Import all keys
--- Import all gossip
--- In an email
function M.setup_import(message)
end

local function expired(key)
end

function M.update_key(addr, force)
	local row = account:where { addr = addr}
	if row == nil then
		return
	end
	if expired(row.public) or force then
		local private, public = make_key(addr)
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
	local accounts = account:get()
	local peers = peer:get()
	--- improve this, this should be as useful as lspinfo
	--- show accounts names, enabled, public(short), prefer for all keys.
	local str = string.format("You have %d of accounts with %d amount of peers", #accounts, #peers)
	vim.notify(str)
end

function M.init()
	vim.fn.mkdir(uri, nil, 0700)
	make_key(config.values.primary_email, false)
end

return M
