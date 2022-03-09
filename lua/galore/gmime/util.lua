-- local gmime = require("galore.gmime.gmime_ffi")
local gs = require("galore.gmime.stream")
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local ge = require("galore.gmime.extra")
local go = require("galore.gmime.object")
-- local f = require("galore.gmime.funcs")
local convert = require("galore.gmime.content")
-- local gmime = require("galore.gmime.stream")
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

function M.internet_address_list_iter(opt, str)
	-- local list = galore.internet_address_list_parse(opt, str)
	local list = gc.internet_address_list_parse(opt, str)
	if list == nil then
		return function ()
			return nil
		end
	end
	local i = 0
	return function()
		if i < gc.internet_address_list_length(list) then
			local addr = gc.internet_address_list_get_address(list, i)
			local mb = ffi.cast("InternetAddressMailbox *", addr)
			local email = gc.internet_address_mailbox_get_addr(mb)
			local name = gc.internet_address_get_name(addr)
			i = i + 1
			return name, email
		end
	end
end

function M.part_is_type(part, type, subtype)
	local content = go.object_get_content_type(part)
	return gc.content_type_is_type(content, type, subtype)
end

function M.part_mime_type(object)
	local ct = go.object_get_content_type(object)
	local type = gc.content_type_get_mime_type(ct)
	return type
end

--- @param path string
--- @return gmime.Message
function M.parse_message(path)
	if not path or path == "" then
		-- assert(false, "Empty path")
		return
	end
	local stream = gs.stream_file_open(path, "r")
	local parser = gs.parser_new_with_stream(stream)
	local message = gs.parser_construct_message(parser, nil)
	return message
end

function M.get_content(part)
	return gp.part_get_content(ffi.cast("GMimePart *", part))
end

function M.save_part(part, filename)
	local stream = assert(gs.stream_file_open(filename, "w"), "can't open file: " .. filename)
	local content = M.get_content(part)
	gs.data_wrapper_write_to_stream(content, stream)
	gs.stream_flush(stream)
end

function M.mem_to_string(mem)
	gs.stream_flush(mem)
	local array = gs.stream_mem_get_byte_array(ffi.cast("GMimeStreamMem *", mem))
	return ffi.string(array.data, array.len)
end

function M.header_iter(message)
	-- local ls = galore.header_list(message)
	local ls = go.object_get_header_list(ffi.cast("GMimeObject *", message))
	if ls then
		local j = gc.header_list_get_count(ls)
		local i = 0
		return function()
			if i < j then
				local header = gc.header_list_get_header_at(ls, i)
				local key = gc.header_get_name(header)
				local value = gc.header_get_value(header)
				i = i + 1
				return key, value
			end
		end
	end
end

function M.is_multipart_alt(object)
	-- local ct = ge.get_content_type(part)
	local type = M.part_mime_type(object)
	if type == "multipart/alternative" then
		return true
	end
	return false
end

function M.reference_iterator(ref)
	local i = 0
	return function()
		if i < gc.references_length(ref) then
			local ret = ffi.string(gc.references_get_message_id(ref, i))
			i = i + 1
			return ret
		end
		gc.references_clear(ref)
	end
end

return M
