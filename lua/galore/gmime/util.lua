--- XXX remove vim-stuff from this later
-- local gmime = require("galore.gmime.gmime_ffi")
local gs = require("galore.gmime.stream")
-- local ffi = require("ffi")

local M = {}

function M.get_password(ctx, uid, prompt, reprompt, response_stream)
	--- use ctx? uid?
	if reprompt then
		prompt = "Try again " .. prompt
	end
	vim.fn.input()
	local input = vim.fn.inputsecret(prompt)
	if input ~= nil or input ~= "" then
		gs.stream_write_string(response_stream, input)
		gs.stream_flush(response_stream)
		return true
	end
	return false
end

return M
