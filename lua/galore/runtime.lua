local config = require("galore.config")
local u = require("galore.util")
local nm = require("notmuch")
local log = require("galore.log")

local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

local runtime_dir = vim.fn.stdpath('data') .. '/galore'
if os.getenv("GALOREPATH") ~= nil then
	runtime_dir = os.getenv("GALOREPATH")
end

local save_file = runtime_dir .. '/nm_saved.txt'

local runtime = {}

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

local function notmuch_init(path, conf, profile)
	local mode = 0
	local db = nm.db_open_with_config_raw(path, mode, conf, profile)
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
	local ok, err = pcall(func, db)
	if not ok then
		log.log(err, vim.log.levels.ERROR)
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
end

local function make_gmime_parser_options()
	local parser_opt = gmime.ParserOptions.new()
	runtime.parser_opts = parser_opt
end

local function make_gmime_format_options()
	local format = gmime.FormatOptions.new()

	runtime.format_opts = format
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
