-- local gm = require("galore.gmime")
local gp = require("galore.gmime.parts")
local go = require("galore.gmime.object")
local gc = require("galore.gmime.content")
local gu = require("galore.gmime.util")
local u = require("galore.util")
local config = require("galore.config")
local ffi = require("ffi")
local jobs = require("galore.jobs")

local M = {}

-- @param filename path to file to include
-- @return A MimePart object containing an attachment
-- Support encryption?
local function create_attachment(filename)
	local cat, type = jobs.get_type(filename)
	local attachment = gm.new_part(cat, type)
	--- XXX part_set__filename
	gm.set_part_filename(attachment, u.basename(filename))
	local stream = gm.stream_open(filename, "r", 0644)

	local content = gm.data_wrapper(stream, "default")
	gm.set_part_content(attachment, content)
	gm.set_encoding(attachment, "base64")
	return attachment
end

local function make_html(part)
	-- overly complicated?
	local content = gm.get_content(part)
	local stream = gm.get_stream(content)
	local filters = gm.new_filter_stream(stream)
	-- No flags atm, flags can convert tabs into spaces etc
	local flags = 0
	local color = config.values.html_color

	local filter = gm.filter_html(flags, color)
	gm.filter_add(filters, filter)
	-- XXX update
	local html_body = gm.new_text_part("html")
	local new_content = gm.get_content(html_body)
	gm.wrapper_set_stream(new_content, filter)
	gm.part_set_content(html_body, new_content)
	gm.stream_flush(filter)
end

-- encrypt a part and return the multipart
-- XXX can we get more graceful crashes?
function M.secure(ctx, part, recipients)
	if config.values.encrypt then
		-- It should be more than just too To, should be all recipients
		local encrypt, err = gm.encrypt(ctx, part, config.values.gpg_id, recipients)
		if encrypt ~= nil then
			return encrypt
		else
			print("Error: " .. err)
		end
	end
	if config.values.sign then
		-- chec if we should do (RFC 4880 and 3156)
		local signed, err = gm.sign(ctx, part, config.values.gpg_id)
		if signed ~= nil then
			return signed
		else
			print("Error: " .. err)
		end
	end
end

function M.save_buf(headers, body, reply, attachment)
	local message = gm.new_message(true)
	for k, v in pairs(headers) do
		for name, email in gm.internet_address_list(nil, v) do
			gm.message_add_mailbox(message, k, name, email)
		end
	end
end

-- create a message from strings
-- @param buf parsed data from the screen, only visual data
-- @param reply, message or nil we use to set reference to
-- @param attachments a list of MimePart objects
-- @return a gmime message
-- XXX We want to set the reply_to (and other mailinglist things)
-- XXX We make it multipart for a simple signed email, which we shouldn't?
-- XXX We need error handling, this should could return nil
function M.create_message(buf, reply, attachments, mode)
	-- move to ctx
	local current
	local message = gp.new_message(true)
	local headers = {"from", "to", "cc", "bcc"} -- etc

	for _, v in ipairs(headers) do
		if buf[v] then
			for name, email in gu.internet_address_list_iter(nil, buf[v]) do
				gp.message_add_mailbox(message, v, name, email)
			end
		end
	end

	if buf.subject then
		gp.message_set_subject(message, buf.subject, nil)
	end

	if reply then
		go.object_set_header(message, "References", reply.reference)
		go.object_set_header(message, "In-Reply-To", reply.in_reply_to)
	end

	local body = gp.text_part_new_with_subtype("plain")
	gp.text_part_set_text(body, table.concat(buf.body, "\n"))
	current = body

	-- if config.values.make_html then
	-- 	local alt = gp.multipart_new_with_subtype("alternative")
	--
	-- 	local html_body = gp.text_part_new_with_subtype("html")
	-- 	gp.text_part_set_text(html_body, buf.body)
	-- 	local html = make_html(html_body)
	-- 	gp.multipart_add(alt, body)
	-- 	gp.multipart_add(alt, html)
	-- 	current = alt
	-- end
	--
	-- if attachments ~= nil and attachments ~= {} then
	-- 	local multipart = gp.multipart_new_with_subtype("mixed")
	-- 	gp.multipart_add(multipart, current)
	-- 	current = multipart
	-- 	for _, file in ipairs(attachments) do
	-- 		local attachment = create_attachment(file)
	-- 		gp.multipart_add(multipart, attachment)
	-- 	end
	-- end
	--
	-- if config.values.encrypt or config.values.sign then
	-- 	local ctx = ge.new_gpg_contex()
	-- 	local secure = M.secure(ctx, current, { buf.To })
	-- 	if secure then
	-- 		current = secure
	-- 	end
	-- end

	gp.message_set_mime_part(message, ffi.cast("GMimeObject *", current))

	return message
end

return M
