-- local gm = require("galore.gmime")
local gp = require("galore.gmime.parts")
local gcu = require("galore.crypt-utils")
local gf = require("galore.gmime.filter")
local gs = require("galore.gmime.stream")
local go = require("galore.gmime.object")
local ge = require("galore.gmime.crypt")
local gc = require("galore.gmime.content")
local gu = require("galore.gmime.util")
local u = require("galore.util")
local config = require("galore.config")
local ffi = require("ffi")
local jobs = require("galore.jobs")
local runtime = require("galore.runtime")

local M = {}

local function stream_open(file, mode, perm)
	local fd = assert(vim.loop.fs_open(file, mode, perm))
	return gs.stream_fs_new(fd)
end

-- @param filename path to file to include
-- @return A MimePart object containing an attachment
-- Support encryption?
local function create_attachment(filename)
	local cat, type = jobs.get_type(filename)
	local attachment = gp.part_new_with_type(cat, type)

	gp.part_set_filename(attachment, u.basename(filename))
	local stream = stream_open(filename, "r", 0644)

	local content = gs.data_wrapper_new_with_stream(stream, "default")
	gp.part_set_content(attachment, content)
	gp.part_set_content_encoding(attachment, "base64")
	return attachment
end

local function make_html(part)
	-- overly complicated?
	local content = gp.part_get_content(part)
	local stream = gs.data_wrapper_get_stream(content)
	local filters = gs.stream_filter_new(stream)
	-- No flags atm, flags can convert tabs into spaces etc
	local flags = 0
	local color = config.values.html_color

	local filter = gf.filter_html_new(flags, color)
	gs.stream_filter_add(filters, filter)
	-- XXX update
	local html_body = gp.text_part_new_with_subtype("html")
	local new_content = gp.part_get_content(html_body)
	gs.wrapper_set_stream(new_content, filter)
	--- Do I need to do this?
	gs.part_set_content(html_body, new_content)
	gs.stream_flush(filter)
end

-- encrypt a part and return the multipart
-- XXX can we get more graceful crashes?
function M.secure(ctx, part, recipients)
	if config.values.encrypt then
		-- It should be more than just too To, should be all recipients
		local encrypt, err = gcu.encrypt(ctx, part, recipients)
		if encrypt ~= nil then
			return encrypt
		else
			-- err isn't a string
			print("Error: " .. err)
		end
	end
	if config.values.sign then
		-- check if we should do (RFC 4880 and 3156)
		local signed, err = gcu.sign(ctx, part)
		if signed ~= nil then
			return signed
		else
			print("Error: " .. err)
		end
	end
end

-- create a message from strings
-- @param buf parsed data from the screen, only visual data
-- @param reply, message or nil we use to set reference to
-- @param attachments a list of MimePart objects
-- @return a gmime message
-- XXX We want to set the reply_to (and other mailinglist things)
-- XXX We need error handling, this should could return nil
function M.create_message(buf, reply, attachments, mode)
	-- move to ctx
	local current
	local message = gp.new_message(true)
	local headers = {"from", "to", "cc", "bcc"} -- etc

	for _, v in ipairs(headers) do
		if buf[v] then
			for name, email in gu.internet_address_list_iter(runtime.parser_opts, buf[v]) do
				gp.message_add_mailbox(message, v, name, email)
			end
		end
	end

	if buf.subject then
		gp.message_set_subject(message, buf.subject, nil)
	end

	if reply then
		go.object_set_header(message, "References", gc.references_format(reply.reference))
		go.object_set_header(message, "In-Reply-To", gc.references_format(reply.in_reply_to))
	end


	local body = gp.text_part_new_with_subtype("plain")
	--- XXX bad, we wan't to roll our own
	gp.text_part_set_text(body, table.concat(buf.body, "\n"))
	current = body

	if config.values.make_html then
		local alt = gp.multipart_new_with_subtype("alternative")

		local html_body = gp.text_part_new_with_subtype("html")
		gp.text_part_set_text(html_body, buf.body)
		local html = make_html(html_body)
		gp.multipart_add(alt, body)
		gp.multipart_add(alt, html)
		current = alt
	end

	if attachments ~= nil and not vim.tbl_isempty(attachments) then
		local multipart = gp.multipart_new_with_subtype("mixed")
		gp.multipart_add(multipart, current)
		current = multipart
		for _, file in ipairs(attachments) do
			local attachment = create_attachment(file)
			gp.multipart_add(multipart, attachment)
		end
	end

	if config.values.encrypt or config.values.sign then
		local ctx = ge.new_gpg_contex()
		local secure = M.secure(ctx, current, { buf.To })
		if secure then
			current = secure
		end
	end

	-- local disp = go.object_get_content_disposition(message)
	-- gc.content_disposition_set_disposition(disp, "inline")
	-- local cont = go.object_get_content_type(message)
	-- gc.content_type_set_media_subtype(cont)
	gp.message_set_mime_part(message, ffi.cast("GMimeObject *", current))

	return message
end

return M
