local gs = require("galore.gmime.stream")
local convert = require("galore.gmime.convert")
local ffi = require("ffi")

local M = {}
--- @param ctx gmime.CryptoContext
--- @param uid string
--- @param prompt string
--- @param reprompt boolean
--- @param response_stream gmime.Stream
-- XXX Move this
function M.get_password(ctx, uid, prompt, reprompt, response_stream)
	--- use ctx? uid?
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

--- @param offset number
--- @param error gmime.ParserWarning
--- @param item string
--- @param _ any
function M.parser_warning(offset, error, item, _)
	local off = tonumber(offset)
	local str = ffi.string(item)
	local error_str = convert.show_parser_warning(error)
	local level = convert.parser_warning_level(error)
	local notification = string.format("Parsing error, %s: %s at: %d ", error_str, str, off)
	vim.notify(notification, level)
end

return M
