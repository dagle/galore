local config = require("galore.config")
local u = require("galore.util")
local nm = require("galore.notmuch")
local log = require("galore.log")

local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

-- TODO Password

local runtime_dir = vim.fn.stdpath('data') .. '/galore'
if os.getenv("GALOREPATH") ~= nil then
	runtime_dir = os.getenv("GALOREPATH")
end

local save_file = runtime_dir .. '/nm_saved.txt'

local runtime = {}

--- remove this later
local function get(db, name)
	return table.concat(u.collect(nm.config_get_values_string(db, name)))
end

local function gets(db, name)
	return u.collect(nm.config_get_values_string(db, name))
end

function runtime.add_saved(str)
	local fp = io.open(save_file, "a")
	if not fp then
		return
	end
	fp:write(str .. "\n")
	fp:close()
end

function runtime.edit_saved()
	if vim.fn.filereadable(save_file) ~= 0 then
		vim.cmd(":e " .. save_file)
	end
end

function runtime.iterate_saved()
	if vim.fn.filereadable(save_file) == 0 then
		return function ()
		end
	end
	return io.lines(save_file)
end

-- local db

--- By default, these variables should be null and use the notmuch default
local function notmuch_init(path, conf, profile)
	local mode = 0
	local db = nm.db_open_with_config_raw(path, mode, conf, profile)
	-- db = nm.db_open_with_config(path, mode, conf, profile)
	local name = get(db, "user.name")
	local primary_email = get(db, "user.primary_email")
	local other_email = gets(db, "user.other_email")
	local exclude_tags = gets(db, "search.exclude_tags")
	local sync_flags = get(db, "maildir.synchronize_flags")
	local mail_root = get(db, "database.mail_root")
	local db_path = get(db, "database.path")
	config.values.name = config.values.name or name
	config.values.synchronize_flags = vim.F.if_nil(config.values.synchronize_flags, sync_flags)
	config.values.primary_email = vim.F.if_nil(config.values.primary_email, primary_email)
	config.values.other_email = vim.F.if_nil(config.values.other_email, other_email)
	config.values.exclude_tags = vim.F.if_nil(config.values.exclude_tags, exclude_tags)
	config.values.mail_root = vim.F.if_nil(config.values.mail_root, mail_root)
	--- shouldn't we just override it at this point?
	config.values.db_path = vim.F.if_nil(config.values.db_path, db_path)
	nm.db_close(db)
end

function runtime.with_db(func)
	local db = nm.db_open_with_config_raw(config.values.db_path, 0, config.values.nm_config, config.values.nm_profile)
	func(db)
	nm.db_close(db)
end

--- for use in async/callback code
function runtime.with_db_raw(func)
	local db = nm.db_open_with_config_raw(config.values.db_path, 0, config.values.nm_config, config.values.nm_profile)
	func(db)
end

function runtime.with_db_writer(func)
	local db = nm.db_open_with_config_raw(config.values.db_path, 1, config.values.nm_config, config.values.nm_profile)
	--- we do pcall here so we don't end up erroring while having a write-lock
	local ok, err = pcall(func, db)
	if not ok then
		vim.notify(err, vim.log.levels.ERROR)
	end
	nm.db_close(db)
end

--- @param offset number
--- @param error gmime.ParserWarning
--- @param item string
local function parser_warning(offset, error, item, _)
	local off = tonumber(offset)
	local str = safe.safestring(item) or ""
	local error_str = convert.show_parser_warning(error)
	local level = convert.parser_warning_level(error)
	local notification = string.format("Parsing error, %s: %s at: %d ", error_str, str, off)
	log.debug(notification)
	-- vim.notify(notification, level)
end

local function make_gmime_parser_options()
	local parser_opt = gmime.ParserOptions.new()
	--- set more stuff
	-- parser_opt:set_warning_callback(parser_warning, nil)
	runtime.parser_opts = parser_opt
end

local function make_gmime_format_options()
	local format = gmime.FormatOptions.new()

	runtime.format_opts = format
end

--- this doesn't seem to work because
--- gpg hates me (it's mutal)
function runtime.get_password(ctx, uid, prompt, reprompt, response_stream)
	--- use ctx? uid?
	--- do we need to convert ui, prompt to string?
	if reprompt then
		prompt = "Try again " .. prompt
	end
	vim.fn.inputsave()
	local input = vim.fn.inputsecret(prompt)
	vim.fn.inputrestore()
	if input ~= nil or input ~= "" then
		-- gs.stream_write_string(response_stream, input)
		return true
	end
	return false
end

function runtime.runtime_dir()
	return runtime_dir
end

function runtime.init()
	if vim.fn.isdirectory(runtime_dir) == 0 then
		if vim.fn.empty(vim.fn.glob(runtime_dir)) == 0 then
			error "runtime_dir exist but isn't a directory"
		end
		vim.fn.mkdir(runtime_dir, "p", "0o700")
	end
	notmuch_init(config.values.db_path, config.values.nm_config, config.values.nm_profile)
	-- runtime.header_function = {}
	make_gmime_parser_options()
	make_gmime_format_options()
end

return runtime
