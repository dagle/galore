local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local gu = require("galore.gmime.util")
local go = require("galore.gmime.object")
local gcu = require("galore.crypt-utils")
local gs = require("galore.gmime.stream")
local gf = require("galore.gmime.filter")
local runtime = require("galore.runtime")
-- local nm = require("galore.notmuch")
local ffi = require("ffi")
local config = require("galore.config")

local M = {}

local function format(str)
	return vim.split(str, "\n", false)
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

local function show_header(buffer, key, value, ns, i, line)
	if value and value ~= "" then
		local str = key .. ": " .. value
		vim.api.nvim_buf_set_lines(buffer, i, i + 1, false, { str })
		if marks[key] and ns then
			marks[key](buffer, ns, i, line)
		end
		return i+1
	end
	return i
end

-- TODO
-- this should also be user defined
function M.show_headers(message, buffer, opts, line, start)
	opts = opts or {}
	local i = start or 0
	local address_headers = {"From", "To", "Cc", "Bcc"}
	for _, head in ipairs(address_headers) do
		local addr = gu.get_addresses(gp.message_get_address(message, head))
		i = show_header(buffer, head, addr, opts.ns, i, line)
	end

	local gdate = gp.message_get_date(message)
	if gdate then
		local date = os.date("%c", gdate)
		i = show_header(buffer, "Date", date, opts.ns, i, line)
	end
	local subject = gp.message_get_subject(message)
	if subject then
		i = show_header(buffer, "Subject", subject, opts.ns, i, line)
	end
	return i
end

--- XXX add a way to configure what filters are used etc
function M.part_to_stream(part, opts, outstream)
	local datawrapper = gp.part_get_content(part)
	local stream = gs.data_wrapper_get_stream(datawrapper)
	gs.stream_reset(stream)
	local filters = gs.stream_filter_new(stream)
	local streamfilter = ffi.cast("GMimeStreamFilter *", filters)

	local enc = gs.data_wrapper_get_encoding(datawrapper)
	if enc then
		local basic = gf.filter_basic_new(enc, false)
		gs.stream_filter_add(streamfilter, basic)
	end

	local object = ffi.cast("GMimeObject *", part)
	local charset = go.object_get_content_type_parameter(object, "charset")
	if charset then
		local utf = gf.filter_charset_new(charset, "UTF-8")
		gs.stream_filter_add(streamfilter, utf)
	end

	local unix = gf.filter_dos2unix_new(false)
	gs.stream_filter_add(streamfilter, unix)

	if opts.reply then
		local reply_filter = gf.filter_reply_new(true)
		gs.stream_filter_add(streamfilter, reply_filter)
	end

	gs.stream_write_to_stream(filters, outstream)
end

-- applies filters and writes it to memory
-- @param part gmime.Part
-- @return string of the part
function M.part_to_string(part, opts)
	local mem = gs.stream_mem_new()
	M.part_to_stream(part, opts, mem)
	return gu.mem_to_string(mem)
end

--- TODO list could be a function
local function rate(object, list)
	local type = gu.part_mime_type(object)
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
	local mp = ffi.cast("GMimeMessagePart *", object)
	local message = gp.message_part_get_message(mp)
	local mobject = ffi.cast("GMimeObject *", message)
	local lang = go.object_get_header(mobject, "Content-Language")
	-- local ttype = go.object_get_header(object, "Content-Translation-Type")
	for i, v in ipairs(list) do
		-- if type(v) == "table" then
		-- 	if lang and ttype and
		-- 		v[1] == lang  ttype == v[2] then
		-- 		return i
		-- 	end
		-- else
		if lang and language_match(v, lang) then
			return i
		end
	end
	return 999
end

-- local rate2 = {"text/plain", "text/enriched", "text/html"}

-- @param message gmime.Message
-- @param state table containing the parts
local function render_message_helper(render, message, buf, opts, state)
	local object = gp.message_get_mime_part(message)
	if object == nil then
		return
	end

	--- I want to remove this too, but let it stay for now
	if opts.reply then
		local date = gp.message_get_date(message)
		local author = gc.internet_address_list_to_string(
				gp.message_get_from(message), runtime.format_opts, false)
		local qoute = config.values.qoute_header(date, author)
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
		if gp.is_multipart_encrypted(part) then
			state.unsafe = true
		end
	end

	gp.message_foreach(message, find_encrypted)
	state.attachments = {}
	state.keys = {}
	render_message_helper(render, message, buf, opts, state)
	return state
end

--- TODO how to do this well?
--- Something like this
function M.add_custom_header(names, render)
	local function custom_header(self, to_obj, buf, opts, state)
		local object = ffi.cast("GMimeObject *", to_obj) --- @type gmime.MimeObject
		local headers = {}
		for _, name in ipairs(names) do
			headers[name] = go.object_get_header(object, name)
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
		local type = gu.part_mime_type(part)
		if type == "text/plain" then
			local str = M.part_to_string(part, opts)
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
		local filename = gp.part_get_filename(part)
		local type = gu.part_mime_type(part)
		local attachment = {filename = filename, part = go.g_object_ref(part), mime_type = type}
		table.insert(state.attachments, attachment)
	end,
	verify = function (self, list, buf, opts, state)
		config.values.annotate_signature(buf, opts.ns, list, before, after, names)
	end,
	encrypted = function (self, mp, buf, opts, state)
		-- Idk, these feels bad, do we only check with key or
		-- we do both?
		local de_part, verified, new_keys
		for _, key in pairs(opts.keys) do
			--- TODO what flags be?
			--- should we really apply all keys and not just with the correct name?
			de_part, verified, new_keys = gcu.decrypt_and_verify(mp, "none", runtime.get_password, key)
			if de_part ~= nil then
				return de_part, verified, new_keys
			end
		end
		de_part, verified, new_keys = gcu.decrypt_and_verify(mp, config.values.decrypt_flags, runtime.get_password, nil)
		return de_part, verified, new_keys
	end,
}

function M.walker(render, object, buf, opts, state)
	if gp.is_message_part(object) then
		local mp = ffi.cast("GMimeMessagePart *", object)
		local message = gp.message_part_get_message(mp)
		render:message(message, buf, opts, state)
	elseif gp.is_part(object) then
		local part = ffi.cast("GMimePart *", object)
		if gp.part_is_attachment(part) then
			if render.attachment then
				render:attachment(part, opts, state)
			end
		else
			if render.part then
				render:part(part, buf, opts, state)
			end
		end
	elseif gp.is_multipart(object) then
		local mp = ffi.cast("GMimeMultipart *", object)
		if gp.is_multipart_encrypted(object) then
			local de_part, verify_list, new_keys = render:encrypted(mp, buf, opts, state)

			if not de_part then
				return
			end

			table.insert(state.keys, new_keys)
			M.walker(render, de_part, buf, opts, state)

			if render.verify then
				vim.schedule(function()
					render:verify(verify_list, opts, state)
				end)
			end
		elseif gp.is_multipart_signed(object) then
			local se_part = gp.multipart_get_part(mp, gp.multipart_signed_content)
			M.walker(render, se_part, buf, opts, state)

			if render.verify then
				vim.schedule(function()
					local list = gcu.verify_signed(object)
					render:verify(list, opts, state)
				end)
			end
		elseif config.values.alt_mode and gu.is_multipart_alt(object) then
			local multi = ffi.cast("GMimeMultipart *", object)
			local saved
			local rating = 1000
			local i = 0
			local j = gp.multipart_get_count(multi)
			while i < j do
				local child = gp.multipart_get_part(multi, i)
				local r = rate(child, config.values.alt_order)
				if r < rating then
					rating = r
					saved = child
				end
				i = i + 1
			end
			M.walker(render, saved, buf, opts, state)
		elseif config.values.multilingual and gu.is_multipart_multilingual(object) then
			local multi = ffi.cast("GMimeMultipart *", object)
			local saved
			local rating = 1000
			local i = 0
			local j = gp.multipart_get_count(multi)
			while i < j do
				local child = gp.multipart_get_part(multi, i)
				local r = rate_lang(child, config.values.lang_order)
				if r < rating then
					rating = r
					saved = child
				end
				i = i + 1
			end
			M.walker(render, saved, buf, opts, state)
		else
			local multi = ffi.cast("GMimeMultipart *", object)
			local i = 0
			local j = gp.multipart_get_count(multi)
			while i < j do
				local child = gp.multipart_get_part(multi, i)
				M.walker(render, child, buf, opts, state)
				i = i + 1
			end
		end
	end
end

return M
