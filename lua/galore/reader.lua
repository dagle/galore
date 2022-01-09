local gm = require('galore.gmime')
local u = require('galore.util')
local conf = require('galore.config')
local ffi = require('ffi')

local M = {}

-- @param filename path to file to include
-- @return A MimePart object containing an attachment
-- Support encryption?
function M.create_attachment(filename)
	local cat, type = u.get_type(filename)
	local attachment = gm.new_part(cat, type)
	gm.set_part_filename(attachment, u.basename(filename))
	local stream = gm.stream_open(filename, 'r', 0644)

	local content = gm.data_wrapper(stream, 'default')
	gm.set_part_content(attachment, content)
	gm.set_encoding(attachment, 'base64')
	return attachment
end

local function make_html(part)
	-- overly complicated?
	local content = gm.get_content(part)
	local stream = gm.get_stream(content)
	local filters = gm.new_filter_stream(stream)
	-- /home/dagle/dump/gmime/gmime/gmime-filter-html.h
	-- XXX fix color and flags
	local flags = 0
	local color = 0

	local filter = gm.filter_html(flags, color)
	gm.filter_add(filters, filter)
	local html_body = gm.new_text_part("html")
	local new_content = gm.get_content(html_body)
	gm.wrapper_set_stream(new_content, filter)
	gm.part_set_content(html_body, new_content)
	gm.stream_flush(filter)

end

-- encrypt a part and return the multipart
-- XXX can we get more graceful crashes?
function M.secure(ctx, part, recipients)
	if conf.values.encrypt then
		-- It should be more than just too To, should be all recipients
		local encrypt, err = gm.encrypt(ctx, part, conf.values.gpg_id, recipients)
		if encrypt ~= nil then
			return encrypt
		else
			print("Error: " .. err)
		end
	end
	if conf.values.sign then
		-- chec if we should do (RFC 4880 and 3156)
		local signed, err = gm.sign(ctx, part, conf.values.gpg_id)
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
-- XXX We make it multipart for a simple signed email, which we shouldn't?
function M.create_message(buf, reply, attachments, mode)
	-- move to ctx
	local ctx = gm.new_gpg_contex()
	local current
	local message = gm.new_message(true)

	-- should do this for more headers
	for name, email in gm.internet_address_list(nil, buf.From) do
		gm.message_add_mailbox(message, 'from', name, email)
	end
	for name, email in gm.internet_address_list(nil, buf.To) do
		gm.message_add_mailbox(message, 'to', name, email)
	end

	gm.message_set_subject(message, buf.Subject, nil)

	if reply then
		-- this shouldn't be here
		local refs, reps = u.make_ref(reply)
		gm.set_header(message, "References", refs)
		gm.set_header(message, "In-Reply-To", reps)
	end

	local body = gm.new_text_part("plain")
	gm.set_text(body, buf.body)

	current = body

	local secure = M.secure(ctx, body, {buf.To})
	if secure then
		current = secure
	end

	if conf.values.make_html then
		-- we make another body and then filter it through html
		local alt = gm.new_multipart("alternative")
		-- maybe I don't need to do this?
		local html_body = gm.new_text_part("plain")
		gm.set_text(html_body, buf.body)
		-- can use body directly?
		local html = make_html(html_body)
		-- generate hmtl
		-- look how the filter does it
		gm.mulitpart_add(alt, body)
		gm.mulitpart_add(alt, html)
		current = alt
	end

	if attachments ~= nil and attachments ~= {} then
		local multipart = gm.new_multipart("mixed")
		gm.multipart_add(multipart, current)
		current = multipart
		for _, attachment in ipairs(attachments) do
			gm.multipart_add(multipart, attachment)
		end
	end
	gm.message_set_mime(message, ffi.cast("GMimeObject *", current))

	return message
end

return M
