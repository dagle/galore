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

local function format(part)
	return vim.split(part, "\n", false)
end

function M.draw(buffer, input)
	vim.api.nvim_buf_set_lines(buffer, -1, -1, true, input)
end

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

function M.show_headers(message, buffer, opts, line)
	opts = opts or {}
	local i = 0
	local address_headers = {"From", "To", "Cc", "Bcc"}
	for _, head in ipairs(address_headers) do
		local addr = gu.get_addresses(gp.message_get_address(message, head))
		i = show_header(buffer, head, addr, opts.ns, i, line)
	end
	local date = os.date("%c", gp.message_get_date(message))
	i = show_header(buffer, "Date", date, opts.ns, i, line)
	local Subject = gp.message_get_subject(message)
	i = show_header(buffer, "Subject", Subject, opts.ns, i, line)
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
	--
	local object = ffi.cast("GMimeObject *", part)
	local charset = go.object_get_content_type_parameter(object, "charset")
	if charset then
		local utf = gf.filter_charset_new(charset, "UTF-8")
		gs.stream_filter_add(streamfilter, utf)
	end
	--
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

-- @param message gmime.Message
-- @param state table containing the parts
local function show_message_helper(message, buf, opts, state)
	local object = gp.message_get_mime_part(message)

	if opts.reply then
		local date = gp.message_get_date(message)
		local author = gc.internet_address_list_to_string(gp.message_get_from(message), nil, false)
		local qoute = config.values.qoute_header(date, author)
		M.draw(buf, { qoute })
	end

	if gp.is_multipart(object) then
		M.show_part(object, buf, opts, state)
	else
		local part = ffi.cast("GMimePart *", object)
		local str = M.part_to_string(part, opts)
		M.draw(buf, format(str))
	end
end

-- @param message gmime.Message
-- @param reply bool if this should be qouted
-- @param opts
-- @return a {body, attachments}, where body is a string and attachments is GmimePart
--- XXX something here converts nil to string
function M.show_message(message, buf, opts)
	-- We set this to "unsafe", this is to battle
	-- This is to handle https://efail.de/ problems
	-- You can ignore this if you want
	-- opts.unsafe = true
	local function find_encrypted(_, part, _, state)
		if gp.is_multipart_encrypted(part) then
			state.unsafe = true
		end
	end

	local state = {}
	gp.message_foreach(message, find_encrypted, state)
	state.attachments = {}
	state.keys = {}
	show_message_helper(message, buf, opts, state)
	return state
end

-- something like this
local function rate(object)
	local type = gu.part_mime_type(object)
	if type == "text/plain" then
		return 5
	elseif type == "text/html" then
		return 3
	end
	return 1
end

--- Encryption exmarks should be configure-able
function M.show_part(object, buf, opts, state)
	if gp.is_message_part(object) then
		local mp = ffi.cast("GMimeMessagePart *", object)
		local message = gp.message_part_get_message(mp)
		show_message_helper(message, buf, opts, state)
	elseif gp.is_part(object) then
		local part = ffi.cast("GMimePart *", object)
		if gp.part_is_attachment(part) then
			local filename = gp.part_get_filename(part)
			state.attachments[filename] = part
		else
			local type = gu.part_mime_type(object)
			if type == "text/plain" then
				local str = M.part_to_string(part, opts)
				M.draw(buf, format(str))
			elseif type == "text/html" then
				local str = M.part_to_string(part, opts)
				local html = config.values.show_html(str, state.unsafe)
				M.draw(buf, html)
			end
		end
	elseif gp.is_multipart(object) then
		local mp = ffi.cast("GMimeMultipart *", object)
		if gp.is_multipart_encrypted(object) then
			if opts.preview then
				opts.preview(buf, "Encrypted")
				return
			end

			local before = vim.fn.line('$') - 1
			local de_part, verified, new_keys
			if not opts.keys or vim.tbl_isempty(opts.keys) then
				de_part, verified, new_keys = gcu.decrypt_and_verify(object, runtime.get_password)
			else
				for _, key in ipairs(opts.keys) do
					de_part, verified, new_keys = gcu.decrypt_and_verify(object, runtime.get_password, key)
				end
			end
			-- if not de_part then
			-- 	de_part, verified = au.decrypt(object)
			-- end
			table.insert(state, new_keys)
			M.show_part(de_part, buf, opts, state)
			local after = vim.fn.line('$') - 1
			local names

			vim.schedule(function()
				config.values.annotate_signature(buf, opts.ns, verified, before, after, names)
			end)
		elseif gp.is_multipart_signed(object) then
			if opts.preview or opts.reply then
				local se_part = gp.multipart_get_part(mp, gp.multipart_signed_content)
				M.show_part(se_part, buf, opts, state)
				return
			end

			local before = vim.fn.line('$') - 1
			local se_part = gp.multipart_get_part(mp, gp.multipart_signed_content)
			M.show_part(se_part, buf, opts, state)
			local after = vim.fn.line('$') - 1

			-- verifying keys can be rather slow
			vim.schedule(function()
				local verified = gcu.verify_signed(object)
				local names
				config.values.annotate_signature(buf, opts.ns, verified, before, after, names)
			end)
		elseif config.values.alt_mode == 1 and gu.is_multipart_alt(object) then
			local multi = ffi.cast("GMimeMultipart *", object)
			local saved
			local rating = 0
			local i = 0
			local j = gp.multipart_get_count(multi)
			while i < j do
				local child = gp.multipart_get_part(multi, i)
				local r = rate(child)
				if r > rating then
					rating = r
					saved = child
				end
				i = i + 1
			end
			M.show_part(saved, buf, opts, state)
		else
			local multi = ffi.cast("GMimeMultipart *", object)
			local i = 0
			local j = gp.multipart_get_count(multi)
			-- for i = 0, j-1 do
			-- end
			while i < j do
				local child = gp.multipart_get_part(multi, i)
				M.show_part(child, buf, opts, state)
				i = i + 1
			end
		end
	end
end

return M
