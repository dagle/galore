local gm = require("galore.gmime")
local gmime = require("galore.gmime.init")
local gp = require("galore.gmime.parts")
local gi = require("galore.gmime.gmime_ffi")
local gc = require("galore.gmime.content")
local u = require("galore.util")
local nm = require("galore.notmuch")
local ffi = require("ffi")
local nu = require("galore.notmuch-util")
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
	local headers = collect(gm.header_iter(message))
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

-- applies filters and writes it to memory
-- @param part a gmime part
-- @return string of the part
local function part_to_string(part, opts)
	local content = gm.get_content(part)
	local stream = gm.get_stream(content)
	gm.stream_reset(stream)
	local filters = gm.new_filter_stream(stream)

	local enc = gm.wrapper_get_encoding(content)
	if enc then
		local basic = gm.filter_basic(enc, false)
		gm.filter_add(filters, basic)
	end

	local charset = gm.get_content_type_parameter(part, "charset")
	if charset then
		local utf = gm.filter_charset(charset, "UTF-8")
		gm.filter_add(filters, utf)
	end

	local unix = gm.filter_dos2unix(false)
	gm.filter_add(filters, unix)

	if opts.reply then
		local reply_filter = gm.filter_reply(true)
		gm.filter_add(filters, reply_filter)
	end

	local mem = gm.new_mem_stream()
	gm.stream_to_stream(filters, mem)
	return gm.mem_to_string(mem)
end

-- @param message gmime.Message
-- @param state table containing the parts
local function show_message_helper(message, buf, opts, state)
	-- local part = gm.mime_part(message)
	local part = gp.message_get_mime_part(message)

	if opts.reply then
		local date = gp.message_get_date(message)
		local author = gc.internet_address_list_to_string(gp.message_get_address(message, gi.GMIME_ADDRESS_TYPE_FROM), nil, false)
		local qoute = conf.values.qoute_header(date, author)
		M.draw(buf, { qoute })
	end

	if gp.is_multipart(part) then
		M.show_part(part, buf, opts, state)
	else
		local str = part_to_string(part, opts)
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
local function rate(part)
	local ct = gm.get_content_type(part)
	local type = gm.get_mime_type(ct)
	if type == "text/plain" then
		return 5
	elseif type == "text/html" then
		return 3
	end
	return 1
end

function M.show_part(object, buf, opts, state)
	if gp.is_message_part(object) then
		local message = gm.get_message(object)
		-- do we want to show that it's a new message?
		show_message_helper(message, buf, opts, state)
	elseif gp.is_partial(object) then
		local full = gm.partial_collect(object)
		-- do we want to show that it's a collected message?
		show_message_helper(full, buf, opts, state)
	elseif gp.is_part(object) then
		-- if gm.is_attachment(part) then
		if gm.get_disposition(object) == "attachment" then
			local ppart = ffi.cast("GMimePart *", object)
			local filename = gm.part_filename(ppart)
			local viewable = gm.part_is_type(object, "text", "*")
			state.attachments[filename] = { ppart, viewable }
			-- table.insert(state.attachments, ppart)
			-- M.parts[filename] = ppart
			local str = "- [ " .. filename .. " ]"
			-- this should be an extmark
			M.draw(buf, { str })

			-- -- local str = gm.print_part(part)
			-- -- v.nvim_buf_set_lines(0, -1, -1, true, split_lines(str))
		else
			-- should contain more stuff
			-- should push some filetypes into attachments
			local ct = gm.get_content_type(object)
			local type = gm.get_mime_type(ct)
			if type == "text/plain" then
				local str = part_to_string(object, opts)
				M.draw(buf, format(str))
			elseif type == "text/html" then
				local str = part_to_string(object, opts)
				local html = conf.values.show_html(str)
				M.draw(buf, html)
			end
		end
	elseif gp.is_multipart(object) then
		-- Can we get a way to show this
		if gp.is_multipart_encrypted(object) then
			if opts.preview then
				-- good enough for now
				-- M.draw(buf, {"Encrypted!"})
				opts.preview(buf, "Encrypted")
				return
			end
			local de_part, sign = gm.decrypt_and_verify(object)
			if sign then
				-- mark("sign confirmed")
				-- table.insert(state.parts, "--- sign confirmed! ---")
			end
			M.show_part(de_part, buf, opts, state)
			return
		elseif gp.is_multipart_signed(object) then
			-- maybe apply some colors etc if the sign is correct or not
			if gm.verify_signed(object) then
				-- mark("sign confirmed")
				-- table.insert(state.parts, "--- sign confirmed! ---")
			end
			local se_part = gm.get_signed_part(object)
			M.show_part(se_part, buf, opts, state)
			-- return something
			return
		elseif conf.values.alt_mode == 1 and gm.is_multipart_alt(object) then
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
