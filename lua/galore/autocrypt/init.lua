--- Because of the limitations of gpg, we are "forced" to do this.

local ok, sqlite = pcall(require, "sqlite.db")
if not ok then
	return
end

local gc = require("galore.gmime.crypt")
local gp = require("galore.gmime.parts")
local gf = require("galore.gmime.funcs")
local gcu = require("galore.crypt-utils")
local gs = require("galore.gmime.stream")
local go = require("galore.gmime.object")
local runtime = require("galore.runtime")
local config = require("galore.config")
local gmime = require("galore.gmime.gmime_ffi")

local tbl = require "sqlite.tbl"

local M = {}
local uri = runtime.runtime_dir() .. "/autocrypt"
local db_path = uri .. "/db.db"
local keyring_path = uri

local account = tbl("account", {
	addr = {type = "text", required = true, primary = true},
	enabled = "number",
	keydata = "text",
	-- keyid = "text",
	prefer = "number"
})

local peer = tbl("peer", {
	addr = {type = "text", required = true, primary = true},
	-- keyid = "text",
	last_seen = "date",
	timestamp = "date",
	keydata = "text",
	prefer = {"number", default = 0},
})

local gossip = tbl("gossip", {
	-- addr = "text",
	addr = {type = "text", required = true, primary = true},
	timestamp = "date",
	-- keyid = "text",
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
	-- return ffi.gc(gmime.au_contex_new(), gmime.g_object_unref)
	return gmime.au_contex_new()
end

function M.with_ctx(func)
	local ctx = create_ctx()
	func(ctx)
	gmime.g_object_unref(ctx)
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
			local stream = gs.stream_mem_new()
			gs.stream_write(stream, gf.gbytes_str(key))
			M.with_ctx(function (ctx)
				gc.crypto_context_import_keys(ctx, stream)
			end)
		end
	end
end

function M.update_gossip(message)
	gc.crypto_context_register("application/pgp-signature", M.ctx)
	gc.crypto_context_register ("application/pgp-encrypted", M.ctx)
	local ahlist = gp.message_get_autocrypt_gossip_headers(message, nil, config.values.decrypt_flags, nil)
	gc.crypto_context_register ("application/pgp-signature", gc.gpg_context_new)
	gc.crypto_context_register ("application/pgp-encrypted", gc.gpg_context_new)
	for ah in gc.autocrypt_header_list_iter(ahlist) do
		local addr = gc.autocrypt_header_get_address_as_string(ah)
		local timestamp = gc.autocrypt_header_get_effective_date(ah)
		local key = gc.autocrypt_header_get_keydata(ah)

		local row = gossip:where { addr = addr }
		if not row then
			local new_row = {
				addr = addr,
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
					timestamp = timestamp,
					keydata = key,
				}
			}
			if key ~= row.key then
				local stream = gs.stream_mem_new()
				gs.stream_write(stream, gf.gbytes_str(key))
				M.with_ctx(function (ctx)
					gc.crypto_context_import_keys(ctx, stream)
				end)
			end
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

--- XXX do this in gpg
local function createkey(path, email, expire)
	local key = gmime.autocrypt_createkey(email)
	-- local err = gpgme_op_createkey(ctx, buf, "ed25519", 0, 0, NULL,
	-- 	GPGME_CREATE_NOPASSWD | GPGME_CREATE_FORCE |
	-- 	GPGME_CREATE_NOEXPIRE);
end

local function make_key(addr)
	local expire = 200
	local key = createkey(keyring_path, addr, expire)
	account:insert({
		addr = addr,
		enabled = 1,
		key = key,
		prefer = 1,
	})
	return key
end

function M.make_key(addr)
	local row = account:where { addr = addr }
	if row then
		return
	end
	vim.ui.input({
		prompt = string.format("Create an autocrypt key for address %s [Y]es/[N]o: ", addr)
	}, function (input)
		if not input then
			return
		end
		input = input:lower()
		if input == "y" or input == "yes" then
			make_key(addr)
		end
	end)
end

local function c_bool(bool)
	return bool and 1 or 0
end

function M.update_account(addr, fields)
	account:update {
		where = { addr = addr},
		set = fields
	}
end

function M.decrypt(object, key)
	gc.crypto_context_register("application/pgp-signature", create_ctx)
	gc.crypto_context_register ("application/pgp-encrypted", create_ctx)
	local de_part, verified = gcu.decrypt_and_verify(object, runtime.get_password, key)

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
	local password = genpassword()
	local message = gp.new_message(true)


	return message
end

--- Import keys from a message
--- Import all accounts
--- Import all keys
--- Import all gossip
--- In an email
function M.setup_import(message, password)
end

local function expired(keydata)
end

local function daydiff(t2, t1, days)
	local diff = os.difftime(t2, t1)
	local secs = days * 3600 * 24
	return diff <= secs
end

local function is_key_valid(key)
	if not key then
		return false
	end
	if daydiff(key.last_seen, key.timestamp, 35)  then
		return true
	end
end

local function get_key(addr)
	local pe = peer:where{addr = addr}
	if pe then
		return pe.keydata
	end
	local gos = gossip:where{ addr = addr}
	if gos then
		return gos.keydata
	end
	return false
end

function M.can_encrypt(recievers)
	for _, rec in ipairs(recievers) do
		local key = get_key(rec)
		if is_key_valid(key) then
			return false
		end
	end
	return true
end

function M.insert_autoheader(message, from)
	local row = account:where { addr = from }
	if row == nil then
		return false
	end
	local ah = gc.autocrypt_header_new()
	gc.autocrypt_header_set_address_from_string(ah, from)
	--- data shouldn't be base64
	gc.autocrypt_header_set_keydata(ah, row.keydata)
	gc.autocrypt_header_set_effective_date(ah, os.time())
	go.object_set_header(message, "Autocrypt", gc.autocrypt_header_to_string(ah, false), nil)
end

-- only do this is part can and will be encrypted
function M.insert_gossip(part, gossips)
	for _, goss in ipairs(gossips) do
		local ah = gc.autocrypt_header_new()
		local data = get_key(goss)
		gc.autocrypt_header_set_address_from_string(ah, goss)
		gc.autocrypt_header_set_keydata(ah, data)
		go.object_append_header(part, "Autocrypt-Gossip", gc.autocrypt_header_to_string(ah, true), nil)
	end
end

function M.update_key(addr, force)
	local row = account:where { addr = addr}
	if row == nil then
		return
	end
	if expired(row.keydata) or force then
		local keydata = make_key(addr)
		account:update{
			where = {addr = addr},
			set = {
				keydata = keydata,
			}
		}
	end
end

function M.delete_account(addr)
	account:remove {addr = addr}
	gmime.delete_key(addr)
	--- remove from gpg
end

-- local account = tbl("account", {
-- 	addr = {type = "text", required = true, primary = true},
-- 	enabled = "number",
-- 	keydata = "text",
-- 	-- keyid = "text",
-- 	prefer = "number"
-- })
--
-- local peer = tbl("peer", {
-- 	addr = {type = "text", required = true, primary = true},
-- 	-- keyid = "text",
-- 	last_seen = "date",
-- 	timestamp = "date",
-- 	keydata = "text",
-- 	prefer = {"number", default = 0},
-- })

local function show_bool(num)
	return tostring(num ~= 0)
end

local function show_acc(buffer, accounts)
	local box = {}
	for _, acc in ipairs(accounts) do
		-- table.insert(box, string.format("Addr: %s, enabled: %s, prefer: %s, keyid: %s"))
		table.insert(box, string.format("Addr: %s, enabled: %s, prefer: %s",
		acc.addr, show_bool(acc.enabled), show_bool(acc.prefer)))
	end
	buffer:set_lines(-1, -1, true, box)
end

local function show_peers(buffer, peers)
	local box = {}
	for _, pe in ipairs(peers) do
		table.insert(box, string.format(""))
	end
	buffer:set_lines(-1, -1, true, box)
end

function M.status()
	local accounts = account:get()
	local peers = peer:get()
	--- improve this, this should be as useful as lspinfo
	--- show accounts names, enabled, public(short), prefer for all keys.
	buffer.create({
		name = "autocrypt-status",
		kind = "floating",
		cursor = "top",
		init = function(buffer)
			show_acc(buffer, accounts)
			show_peers(buffer, accounts)
	        buffer:setlines(0, 0, true, {string.format("You have %d of accounts with %d peers", #accounts, #peers)})
		end,
	})
end

function M.init()
	if vim.fn.isdirectory(uri) == 0 then
		if vim.fn.empty(vim.fn.glob(uri)) == 0 then
			error "autocrypt exist but isn't a directory"
		end
		vim.fn.mkdir(uri, "p", "0o700")
	end
	M.make_key(config.values.primary_email)
end

return M
