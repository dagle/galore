local gm = require('galore.gmime')
local u = require('galore.util')
local ffi = require('ffi')
local conf = require('galore.config')

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

local function mark(buffer, start, stop)
	-- nvim_buf_add_highlight()
	-- vim.api.nvim_buf_del_extmark(buffer.handle, ns_id: number, id: number)
end

function M.show_all_message(message, buffer, opts)
	M.show_header(message, buffer)
	M.show_message(message, buffer, opts)
end


function M.save_path(filename, default_path)
	local path
	default_path = default_path or ""
	if M.is_absolute(filename) then
		path = filename
	else
		path = default_path .. filename
	end
	return path
end

local function collect(iter)
	local box = {}
	for k,val in iter do
		box[k] = val
	end
	return box
end

local function filter(func, map)
	for k, v in pairs(map) do
		if not func(k,v) then
			map[k] = nil
		end
	end
end

local function in_map(k,_)
	for _, a in ipairs(conf.values.headers) do
		if a == k then
			return true
		end
	end
	return false
end

local function format_header(iter)
	local box = {}
	for k, val in pairs(iter) do
		local str = string.gsub(val,"\n", "")
		table.insert(box, k .. ": " .. str)
	end
	return box
end
-- XXX fix this, it feels really ugly
-- XXX don't show marks in 
function M.show_header(message, buffer)
	local headers = collect(gm.header_iter(message))
	filter(in_map, headers)
	vim.api.nvim_buf_set_lines(buffer, 0, 0, false, format_header(headers))
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
		local reply_filter= gm.filter_reply(true)
		gm.filter_add(filters, reply_filter)
	end

	local mem = gm.new_mem_stream()
	gm.stream_to_stream(filters, mem)
	return gm.mem_to_string(mem)
end


-- @param message gmime message
-- @param state table containing the parts
local function show_message_helper(message, buf, opts, state)
	local part = gm.mime_part(message)

	if opts.reply then
		local date = gm.message_get_date(message)
		local author = gm.show_addresses(gm.message_get_address(message, 'from'))
		local qoute = conf.values.qoute_header(date, author)
		M.draw(buf, {qoute})
	end

	if gm.is_multipart(part) then
		M.show_part(part, buf, opts, state)
	else
		local str = part_to_string(part, opts)
		M.draw(buf, format(str))
	end
end

-- @param message gmime message
-- @param reply bool if this should be qouted
-- @param opts 
-- @return a {body, attachments}, where body is a string and attachments is GmimePart
function M.show_message(message, buf, opts)
	local box = {}
	box.attachments = {}
	show_message_helper(message, buf, opts, box)
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

function M.show_part(part, buf, opts, state)
	if gm.is_message_part(part) then
		local message = gm.get_message(part)
		-- do we want to show that it's a new message?
		show_message_helper(message, buf, opts, state)
	elseif gm.is_partial(part) then
		local full = gm.partial_collect(part)
		-- do we want to show that it's a collected message?
		show_message_helper(full, buf, opts, state)
	elseif gm.is_part(part) then
		-- if gm.is_attachment(part) then
		if gm.get_disposition(part) == "attachment" then
			local ppart = ffi.cast("GMimePart *", part)
			table.insert(state.attachments, ppart)
			local filename = gm.part_filename(ppart)
			-- M.parts[filename] = ppart
			local str = "- [ " .. filename .. " ]"
			M.draw(buf, {str})

			-- -- local str = gm.print_part(part)
			-- -- v.nvim_buf_set_lines(0, -1, -1, true, split_lines(str))
		else
			-- should contain more stuff
			-- should push some filetypes into attachments
			local ct = gm.get_content_type(part)
			local type = gm.get_mime_type(ct)
			if type == "text/plain" then
				local str = part_to_string(part)
				M.draw(buf, format(str))
			elseif type == "text/html" then
				local str = part_to_string(part)
				local html = conf.values.show_html(str)
				M.draw(buf, html)
			end
		end
	elseif gm.is_multipart(part) then
		if gm.is_multipart_encrypted(part) then
			-- display as "encrypted part, until it's decrypted, then refresh the renderer"
			local de_part, sign = gm.decrypt_and_verify(part)
			if sign then
				mark("sign confirmed")
				-- table.insert(state.parts, "--- sign confirmed! ---")
			end
			M.show_part(de_part, buf, opts, state)
			return
		elseif gm.is_multipart_signed(part) then
			-- maybe apply some colors etc if the sign is correct or not
			if gm.verify_signed(part) then
				mark("sign confirmed")
				-- table.insert(state.parts, "--- sign confirmed! ---")
			end
			local se_part = gm.get_signed_part(part)
			M.show_part(se_part, buf, opts, state)
			-- return something
			return
		elseif conf.values.alt_mode == 1 and gm.is_multipart_alt(part) then
			local multi = ffi.cast("GMimeMultipart *", part)
			local saved
			local rating = 0
			local i = 0
			local j = gm.multipart_len(multi)
			while i < j do
				local child = gm.multipart_child(multi, i)
				local r = rate(child)
				if r > rating then
					rating = r
					saved = child
				end
				i = i + 1
			end
			M.show_part(saved, buf, opts, state)
        else
			local multi = ffi.cast("GMimeMultipart *", part)
			local i = 0
			local j = gm.multipart_len(multi)
			-- for i = 0, j-1 do
			-- end
			while i < j do
				local child = gm.multipart_child(multi, i)
				M.show_part(child, buf, opts, state)
				i = i + 1
			end
		end
	end
end

return M
