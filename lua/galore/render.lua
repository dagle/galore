local gp = require("galore.gmime.parts")
local gi = require("galore.gmime.gmime_ffi")
local gc = require("galore.gmime.content")
local gu = require("galore.gmime.util")
local go = require("galore.gmime.object")
local ge = require("galore.gmime.crypt")
local gs = require("galore.gmime.stream")
local gf = require("galore.gmime.filter")
local u = require("galore.util")
local nm = require("galore.notmuch")
local ffi = require("ffi")
local conf = require("galore.config")

local M = {}

local function format(part, qoute)
	local box = {}
	for line in string.gmatch(part, "[^\n]+") do
		table.insert(box, line)
		-- if qoute then
		-- 	table.insert(box, "> " .. line)
		-- end
	end
	return box
end

function M.draw(buffer, input)
	-- check if input is a string or a table
	vim.api.nvim_buf_set_lines(buffer, -1, -1, true, input)
end

--- move this
local function collect(iter)
	local box = {}
	for k, val in iter do
		box[k] = val
	end
	return box
end

local function mark(buffer, ns, content, i)
	local line_num = i
	local col_num = 0

	local opts = {
		virt_text = { { content, "Comment" } },
	}
	vim.api.nvim_buf_set_extmark(buffer, ns, line_num, col_num, opts)
end

local marks = {
	From = function(buffer, ns, i, nm_message)
		local tags = table.concat(u.collect(nm.message_get_tags(nm_message)), " ")
		mark(buffer, ns, "(" .. tags .. ")", i)
	end,
	-- this creashes luajit, also it might be a bad idea
	-- Subject = function (buffer, ns, i, nm_message)
	-- local count = nu.message_with_thread(nm_message, function (thread)
	-- 	local tot = nm.thread_get_total_messages(thread)
	-- 	local current = nu.get_index(thread, nm_message)
	-- 	return string.format("[%02d/%02d]", current, tot)
	-- end)
	-- mark(buffer, ns, count, i)
	-- end
}

function M.show_header(message, buffer, opts, nm_message)
	opts = opts or {}
	local headers = collect(gu.header_iter(message))
	local i = 0
	for _, k in ipairs(conf.values.headers) do
		if headers[k] then
			local str = string.gsub(k .. ": " .. headers[k], "\n", "")
			vim.api.nvim_buf_set_lines(buffer, i, i + 1, false, { str })
			if marks[k] and opts.ns then
				marks[k](buffer, opts.ns, i, nm_message)
			end
			i = i + 1
		end
	end
end

function M.part_to_stream(part, opts, outstream)
	local datawrapper = gp.part_get_content(part)
	local stream = gs.data_wrapper_get_stream(datawrapper)
	gs.stream_reset(stream)
	local filters = gs.stream_filter_new(stream)
	local streamfilter = ffi.cast("GMimeStreamFilter *", filters)

	--- XXX add a way to configure this
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

-- @param message gmime.Message
-- @param state table containing the parts
local function show_message_helper(message, buf, opts, state)
	local object = gp.message_get_mime_part(message)

	if opts.reply then
		local date = gp.message_get_date(message)
		local author = gc.internet_address_list_to_string(gp.message_get_address(message, gi.GMIME_ADDRESS_TYPE_FROM), nil, false)
		local qoute = conf.values.qoute_header(date, author)
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
function M.show_message(message, buf, opts)
	local box = {}
	box.attachments = {}
	show_message_helper(message, buf, opts, box)
	return box.attachments
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

function M.show_part(object, buf, opts, state)
	if gp.is_message_part(object) then
		local mp = ffi.cast("GMimeMessagePart *", object)
		local message = gp.message_part_get_message(mp)
		show_message_helper(message, buf, opts, state)
	elseif gp.is_partial(object) then
		--- XXX todo, handle partial
		-- local mp = ffi.cast("GMimeMessagePartial *", object)
		-- local full = gm.partial_collect(object)
		-- do we want to show that it's a collected message?
		-- show_message_helper(full, buf, opts, state)
	elseif gp.is_part(object) then
		local part = ffi.cast("GMimePart *", object)
		if gp.part_is_attachment(part) then
			local filename = gp.part_get_filename(part)
			local viewable = gu.part_is_type(object, "text", "*")
			state.attachments[filename] = { part, viewable }
			local str = "- [ " .. filename .. " ]"
			-- this should be an extmark
			M.draw(buf, { str })
		else
			local type = gu.part_mime_type(object)
			if type == "text/plain" then
				local str = M.part_to_string(part, opts)
				M.draw(buf, format(str))
			elseif type == "text/html" then
				local str = M.part_to_string(part, opts)
				local html = conf.values.show_html(str)
				M.draw(buf, html)
			end
		end
	elseif gp.is_multipart(object) then
		local mp = ffi.cast("GMimeMultipart *", object)
		-- Can we get a way to show this
		if gp.is_multipart_encrypted(object) then
			local de_part, sign = ge.decrypt_and_verify(object)
			if sign then
			end
			M.show_part(de_part, buf, opts, state)
			return
		elseif gp.is_multipart_signed(object) then
			-- local multi = ffi.cast("GMimeMultipart *", object)
			-- local signed = ffi.cast("GMimeMultipartSigned *", part)
			if ge.verify_signed(object) then
			end
			local se_part = gp.multipart_get_part(mp, 0)
			M.show_part(se_part, buf, opts, state)
			return
		elseif conf.values.alt_mode == 1 and gu.is_multipart_alt(object) then
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
