local config = require("galore.config")
local gcu = require("galore.crypt-utils")
local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")
local gu = require("galore.gmime-util")

local M = {}

local function format(str)
	return vim.split(str, "\n", false)
end

local function mime_type(object)
	local ct = object:get_content_type()
	local type = ct:get_mime_type()
	return type
end

-- TODO
-- these should be user defined
-- and users should be able to easily 
local function mark(buffer, ns, content, i)
	local line_num = i
	local col_num = 0

	local opts = {
		virt_text = { { content, "GaloreHeader" } },
	}
	vim.api.nvim_buf_set_extmark(buffer, ns, line_num, col_num, opts)
end

local marks = {
	From = function(buffer, ns, i, line)
		local tags = table.concat(line.tags, " ")
		mark(buffer, ns, "(" .. tags .. ")", i)
	end,
	Subject = function(buffer, ns, i, line)
		if line.index and line.total then
			local str = string.format("[%d/%d]", line.index, line.total)
			mark(buffer, ns, str, i)
		end
	end
}

local function show_key(key)
	local at = gmime.AddressType
	if key == at.SENDER then
		return "Sender"
	end
	if key == at.FROM then
		return "From"
	end
	if key == at.REPLY_TO then
		return "Reply_to"
	end
	if key == at.TO then
		return "To"
	end
	if key == at.CC then
		return "Cc"
	end
	if key == at.BCC then
		return "Bcc"
	end
end

local function show_header(buffer, key, value, ns, i, line)
	if value and value ~= "" then
		local str = key .. ": " .. value
		local lines = vim.fn.split(str, "\n")
		vim.api.nvim_buf_set_lines(buffer, i, i + 1, false, lines)
		if marks[key] and ns then
			marks[key](buffer, ns, i, line)
		end
		return i+#lines
	end
	return i
end

-- TODO
-- this should also be user defined
function M.show_headers(message, buffer, opts, line, start)
	local at = gmime.AddressType
	opts = opts or {}
	local i = start or 0
	local address_headers = {at.FROM, at.TO, at.CC, at.BCC} --[[ gmime.AddressType.SENDER ]]
	for _, head in ipairs(address_headers) do
		local addr = message:get_addresses(head)
		local addr_str = addr:to_string(nil, false)
		i = show_header(buffer, show_key(head), addr_str, opts.ns, i, line)
	end

	local date = message:get_date()
	local num = date:to_unix()
	local date_str = os.date("%c", num)
	i = show_header(buffer, "Date", date_str, opts.ns, i, line)
	local subject = message:get_subject()
	i = show_header(buffer, "Subject", subject, opts.ns, i, line)
	return i
end

--- XXX add a way to configure what filters are used etc
function M.part_to_stream(part, opts, outstream)
	local dw = part:get_content()
	local stream = dw:get_stream()
	stream:reset()
	local filters = gmime.StreamFilter.new(stream)

	local enc = dw:get_encoding()
	if enc then
		local basic = gmime.FilterBasic.new(enc, false)
		filters:add(basic)
	end

	local charset = part:get_content_type_parameter("charset")
	if charset then
		local utf8 = gmime.FilterCharset.new(charset, "UTF-8")
		filters:add(utf8)
	end

	local unix = gmime.FilterDos2Unix.new(false)
	filters:add(unix)

	if opts.reply then
		local reply_filter = gmime.FilterReply.new(true)
		filters:add(reply_filter)
	end

	filters:write_to_stream(outstream)
end

-- @param part gmime.Part
-- @return string
function M.part_to_string(part, opts)
	local mem = gmime.StreamMem.new()
	M.part_to_stream(part, opts, mem)
	return mem:get_byte_array()
end

local function rate_function(render, buf, opts, state, object, fun)
	local saved
	local rating = 1000
	local i = 0
	local j = object:get_count()
	while i < j do
		local child = object:get_part(i)
		local r = fun(child)
		if r < rating then
			rating = r
			saved = child
		end
		i = i + 1
	end
	M.walker(render, saved, buf, opts, state)
end

--- TODO list could be a function
local function rate_alt(object, list)
	local type = mime_type(object)
	for i, v in ipairs(list) do
		if v == type then
			return i
		end
	end
	return 999
end

local function language_match(lang1, lang2)
	local function split(inputstr, sep)
		for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			return str
		end
	end

	lang1 = lang1:lower()
	lang1 = lang2:lower()
	if lang1 == lang2 then
		return true
	end
	local head1 = split(lang1, "-_")
	local head2 = split(lang1, "-_")
	return head1[1] == head2[1]
end

--- TODO list could be a function
--- Also do we want to be able to rewrite the Subject and From
--- using From and Subject in the message?
local function rate_lang(object, list)
	-- local mp = ffi.cast("GMimeMessagePart *", object)
	-- local message = gp.message_part_get_message(mp)
	-- local mobject = ffi.cast("GMimeObject *", message)
	-- local lang = go.object_get_header(mobject, "Content-Language")
	-- local ttype = go.object_get_header(object, "Content-Translation-Type")
	-- for i, v in ipairs(list) do
	-- 	-- if type(v) == "table" then
	-- 	-- 	if lang and ttype and
	-- 	-- 		v[1] == lang  ttype == v[2] then
	-- 	-- 		return i
	-- 	-- 	end
	-- 	-- else
	-- 	if lang and language_match(v, lang) then
	-- 		return i
	-- 	end
	-- end
	return 999
end

-- @param message gmime.Message
-- @param state table containing the parts
local function render_message_helper(render, message, buf, opts, state)
	local object = message:get_mime_part()
	if object == nil then
		return
	end

	--- I want to remove this too, but let it stay for now
	if opts.reply then
		local date = message:get_date()
		local num = date:to_unix()

		-- export a date and author intead? Or the whole message?
		local author = message:get_from()
		local str = author:to_string()
		local qoute = config.values.qoute_header(num, str)
		render.draw(buf, { qoute })
	end

	M.walker(render, object, buf, opts, state)
end

-- @param message gmime.Message
-- @param reply bool if this should be qouted
-- @param opts
-- @return a table with state
function M.render_message(render, message, buf, opts)
	-- We set this to "unsafe", this is to battle
	-- This is to handle https://efail.de/ problems
	-- You can ignore this if you want
	-- opts.unsafe = true
	local state = {}
	local function find_encrypted(_, part, _)
		if gmime.MultipartEncrypted:is_type_of(part) then
			state.unsafe = true
		end
	end

	message:foreach(find_encrypted)

	state.attachments = {}
	state.keys = {}
	state.callbacks = {}
	render_message_helper(render, message, buf, opts, state)
	return state
end

--- TODO how to do this well?
--- Something like this
function M.add_custom_header(names, render)
	local function custom_header(self, object, buf, opts, state)
		local headers = {}
		for _, name in ipairs(names) do
			headers[name] = object.get_header(object, name)
		end
		for k, v in pairs(headers) do
			local str = string.format("%s:%s", k, v)
			self.draw(buf, format(str))
		end
	end
	M.prepend({
		message = function (self, message, buf, opts, state)
			custom_header(self,message, buf, opts, state)
		end,
		part = function (self, part, buf, opts, state)
			custom_header(self, part, buf, opts, state)
		end,
	},
	render)
end

function M.new(opts, defaults)
	opts = opts or {}
	defaults = defaults or {}
	local result = {}

	for k, v in pairs(defaults) do
		assert(type(k) == "string", "Should be string, found: " .. type(k))
		result[k] = v
	end

	for k, v in pairs(opts) do
		assert(type(k) == "string", "Should be string, found: " .. type(k))
		result[k] = v
		if v == false then
			result[k] = nil
		end
	end

	return result
end

function M.extend(opts, defaults)
	opts = opts or {}
	defaults = defaults or {}
	local result = {}

	for k, v in pairs(defaults) do
		assert(type(k) == "string", "Should be string, found: " .. type(k))
		result[k] = v
	end

	for k, v in pairs(opts) do
		if result[k] == nil then
			assert(type(k) == "string", "Should be string, found: " .. type(k))
			result[k] = v
		else
			local default_value = result[k]
			result[k] = function (...)
				default_value(...)
				return v(...)
			end
		end
	end

	return result
end

function M.prepend(opts, defaults)
	opts = opts or {}
	defaults = defaults or {}
	local result = {}

	for k, v in pairs(defaults) do
		assert(type(k) == "string", "Should be string, found: " .. type(k))
		result[k] = v
	end

	for k, v in pairs(opts) do
		if result[k] == nil then
			assert(type(k) == "string", "Should be string, found: " .. type(k))
			result[k] = v
		else
			local default_value = result[k]
			result[k] = function (...)
				v(...)
				return default_value(...)
			end
		end
	end

	return result
end

--- what should a function take? (opts/state needed?)
M.default_render = {
	message = function (self, message, buf, opts, state)
		render_message_helper(self, message, buf, opts, state)
	end,
	part = function (self, part, buf, opts, state)
		local type = mime_type(part)
		if type == "text/plain" then
			local str = M.part_to_string(part, opts)
			-- TODO this crashes sometimes
			if str == nil then str = "" end
			self.draw(buf, format(str))
		elseif type == "text/html" then
			local str = M.part_to_string(part, opts)
			local html = config.values.show_html(str, state.unsafe)
			self.draw(buf, html)
		end
	end,
	draw = function (buf, str)
		vim.list_extend(buf, str)
	end,
	attachment = function (self, part, opts, state)
		local filename = part:get_filename(part)
		local type = mime_type(part)
		local attachment = {filename = filename, part = part, mime_type = type}
		table.insert(state.attachments, attachment)
	end,
	verify = function (self, bufnr, ns, list, before, after, names)
			config.values.annotate_signature(bufnr, ns, list, before, after, names)
	end,
	encrypted = function (self, mp, buf, opts, state)
		-- Idk, these feels bad, do we only check with key or
		-- we do both?
		local de_part, verified, new_keys
		for _, key in pairs(opts.keys) do
			--- TODO what flags be?
			--- should we really apply all keys and not just with the correct name?
			de_part, verified, new_keys = gcu.decrypt_and_verify(mp, "none", key)
			if de_part ~= nil then
				return de_part, verified, new_keys
			end
		end
		-- de_part, verified, new_keys = gcu.decrypt_and_verify(mp, config.values.decrypt_flags, runtime.get_password, nil)
		return de_part, verified, new_keys
	end,
}

local signed_content = 0
-- local signed_signature = 1

function M.walker(render, object, buf, opts, state)
	if gmime.MessagePart:is_type_of(object) then
		local message = object:get_message()
		render:message(message, buf, opts, state)
	elseif gmime.Part:is_type_of(object) then
		if object:is_attachment() then
			if render.attachment then
				render:attachment(object, opts, state)
			end
		else
			if render.part then
				render:part(object, buf, opts, state)
			end
		end
	elseif gmime.Multipart:is_type_of(object) then
		if gmime.MultipartEncrypted:is_type_of(object) then
			local de_part, verify_list, new_keys = render:encrypted(object, buf, opts, state)

			if not de_part then
				return
			end

			table.insert(state.keys, new_keys)
			-- maybe these are a bad idea?
			-- local before = #buf + opts.offset
			M.walker(render, de_part, buf, opts, state)
			-- local after = #buf + opts.offset - 1

			if render.verify then
				table.insert(state.callbacks, function (bufnr, ns)
					-- what is names?
					render:verify(bufnr, ns, verify_list, before, after, nil)
				end)
			end
		elseif gmime.MultipartSigned:is_type_of(object) then
			local se_part = object:get_part(signed_content)
			-- maybe these are a bad idea?
			-- local before = #buf + opts.offset
			M.walker(render, se_part, buf, opts, state)
			-- local after = #buf + opts.offset - 1

			if render.verify then
				table.insert(state.callbacks, function (bufnr, ns)
					local verify_list = gcu.verify_signed(object)
					render:verify(bufnr, ns, verify_list, before, after, nil)
				end)
			end
		elseif config.values.alt_mode and gu.is_multipart_alt(object) then
			rate_function(render, buf, opts, state, object, function (child)
				return rate_alt(child, config.values.alt_order)
			end)
		elseif config.values.multilingual and gu.is_multipart_multilingual(object) then
			rate_function(render, buf, opts, state, object, function (child)
				return rate_lang(child, config.lang_order)
			end)
		elseif config.values.related and gu.is_multipart_related(object) then
			-- TODO
		else
			local i = 0
			local j = object:get_count()
			while i < j do
				local child = object:get_part( i)
				M.walker(render, child, buf, opts, state)
				i = i + 1
			end
		end
	end
end

return M
