--- Runtime keeps track of the following:
--- notmuchdb_handler, parser_opts, format_opts, and crypto-ctx 
local config = require("galore.config")
local u = require("galore.util")
local nm = require("galore.notmuch")
local gopt = require("galore.gmime.option")
local convert = require("galore.gmime.convert")
local ge = require("galore.gmime.crypt")
local gs = require("galore.gmime.stream")
local ffi = require("ffi")

local runtime = {}

--- remove this later
local function get(db, name)
	return table.concat(u.collect(nm.config_get_values_string(db, name)))
end

local function gets(db, name)
	return u.collect(nm.config_get_values_string(db, name))
end

--- By default, these variables should be null and use the notmuch default
local function notmuch_init(path, conf, profile)
	local mode = 0
	local db = nm.db_open_with_config(path, mode, conf, profile)
	local name = get(db, "user.name")
	local primary_email = get(db, "user.primary_email")
	local other_email = gets(db, "user.other_email")
	local exclude_tags = gets(db, "search.exclude_tags")
	runtime.db = db
	config.values.name = config.values.name or name
	config.values.primary_email = config.values.primary_email or primary_email
	config.values.other_email = config.values.other_email or other_email
	config.values.exclude_tags = config.values.exclude_tags or exclude_tags
end

--- @param offset number
--- @param error gmime.ParserWarning
--- @param item string
--- @param data nil
local function parser_warning(offset, error, item, data)
	local off = tonumber(offset)
	local str = ffi.string(item)
	local error_str = convert.show_parser_warning(error)
	local level = convert.parser_warning_level(error)
	local notification = string.format("Parsing error, %s: %s at: %d ", error_str, str, off)
	vim.notify(notification, level)
end

local function make_gmime_parser_options()
	local parser = gopt.parser_options_new()
	--- set more stuff
	gopt.parser_options_set_warning_callback(parser, parser_warning, nil)
	runtime.parser_opts = parser
end

local function make_gmime_format_options()
	local format = gopt.format_options_new()

	runtime.format_opts = format
end

function runtime.get_password(ctx, uid, prompt, reprompt, response_stream)
	--- use ctx? uid?
	--- do we need to convert ui, prompt to string?
	if reprompt then
		prompt = "Try again " .. prompt
	end
	local input = vim.fn.inputsecret(prompt)
	if input ~= nil or input ~= "" then
		gs.stream_write_string(response_stream, input)
		gs.stream_flush(response_stream)
		return true
	end
	return false
end

function runtime.init()
	notmuch_init(config.values.db_path, config.values.nm_config, config.values.nm_profile)
	make_gmime_parser_options()
	make_gmime_format_options()
end

return runtime
