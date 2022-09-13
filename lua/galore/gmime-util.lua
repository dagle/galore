local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

local M = {}

function M.mime_type(object)
	local ct = object:get_content_type()
	local type = ct:get_mime_type()
	return type
end

function M.parse_message(filename)
	local stream = gmime.StreamFile.open(filename, "r")
	local parser = gmime.Parser.new_with_stream(stream)
	local opts = gmime.ParserOptions.new()
	local message = parser:construct_message(opts)
	return message
end

function M.make_ref(message, opts)
	local ref_str = message:get_header("References")
	local ref
	if ref_str then
		ref = gmime.References.parse(nil, ref_str)
	else
		ref = gmime.References.new()
	end
	local mid = message:get_message_id()
	local reply = gmime.Reference.parse(nil, mid)
	ref:append(mid)
	opts.headers = opts.headers or {}
	opts.headers.References = M.references_format(ref)
	opts.headers["In-Reply-To"] = M.references_format(reply)
end

function M.references_format(refs)
	if refs == nil then
		return nil
	end
	local box = {}
	for ref in M.reference_iter(refs) do
		table.insert(box, "<" .. ref .. ">")
	end
	return table.concat(box, "\n\t")
end

function M.is_multipart_alt(object)
	local type = M.mime_type(object)
	if type == "multipart/alternative" then
		return true
	end
	return false
end

function M.is_multipart_multilingual(object)
	local type = M.mime_type(object)
	if type == "multipart/alternative" then
		return true
	end
	return false
end

function M.is_multipart_related(object)
	local type = M.mime_type(object)
	if type == "multipart/alternative" then
		return true
	end
	return false
end

function M.multipart_foreach_level(part, parent, fun, level)
	if parent ~= part then
		fun(parent, part, level)
	end
	if gmime.Multipart:is_type_of(part) then
		local i = 0
		local j = part:get_count()
		level = level + 1
		while i < j do
			local child = part:get_part(i)
			M.multipart_foreach_level(child, part, fun, level)
			i = i + 1
		end
	end
end

function M.message_foreach_level(message, fun)
	local level = 1
	if not message or not fun then
		return
	end
	local part = message:get_mime_part()
	fun(part, part, level)

	if gmime.Multipart:is_type_of(part) then
		M.multipart_foreach_level(part, part, fun, level)
	end
end

--- @param str string
--- @param opts gmime.ParserOptions|nil
--- @return function
function M.reference_iter_str(str, opts)
	local refs = gmime.Reference.parse(opts, str)
	if refs == nil then
		return function ()
			return nil
		end
	end
	return M.reference_iter(refs)
end

--- @return function
function M.reference_iter(refs)
	local i = 0
	return function()
		if i < refs:length() then
			local ref = refs:get_message_id(refs, i)
			i = i + 1
			return ref
		end
	end
end

function M.header_iter(object)
	local ls = object:get_header_list()
	if ls == nil then
		return function ()
			return nil
		end
	end
	local j = ls:get_count()
	local i = 0
	return function()
		if i < j then
			local header = ls:get_header_at(i)
			if header == nil then
				return nil, nil
			end
			local key = header:get_name()
			local value = header:get_value()
			i = i + 1
			return key, value
		end
	end
end

--- TODO
function M.internet_address_list_iter_str(str, opt)
	local list = M.internet_address_list_parse(opt, str)
	if list == nil then
		return function ()
			return nil
		end
	end
	return M.internet_address_list_iter(list)
end

function M.internet_address_list_iter(list)
	local i = 0
	return function()
		if i < M.internet_address_list_length(list) then
			local addr = M.internet_address_list_get_address(list, i)
			i = i + 1
			return addr
		end
	end
end

function M.ialist_contains(ia2, ialist)
	for ia1 in gc.internet_address_list_iter(ialist) do
		if M.address_equal(ia1, ia2) then
			return true
		end
	end
	return false
end

return M
