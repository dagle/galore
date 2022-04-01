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

local function required_headers(buf)
	return buf.from and buf.to and buf.subject
end

-- create a message from strings
-- @param buf parsed data from the screen, only visual data
-- @param reply, message or nil we use to set reference to
-- @param attachments a list of MimePart objects
-- @return a gmime message
-- XXX We want to set the reply_to (and other mailinglist things)
-- XXX We need error handling, this should could return nil
function M.create_message(buf, reply, attachments, opts)
	opts = opts or {}
	local current
	local message = gp.new_message(true)
	local mobj = ffi.cast("GMimeObject *", message)
	local headers = {"from", "to", "cc", "bcc"} -- etc
	--- From and too should be required

	if not required_headers(buf) then
		vim.notify("Missing non-optional headers", vim.log.levels.ERROR)
		return
	end

	for _, v in ipairs(headers) do
		if buf[v] then
			for name, email in gu.internet_address_list_iter(runtime.parser_opts, buf[v]) do
				gp.message_add_mailbox(message, v, name, email)
			end
		end
	end
	local list = go.object_get_header_list(ffi.cast("GMimeObject *", message))

	for _, email in gu.internet_address_list_iter(runtime.parser_opts, buf.from) do
		local id = gu.make_id(email)
		go.object_set_header(mobj, "Message-ID", id)
	end

	gu.insert_current_date(message)

	--- this shouldn't be optional, set it to no-topic
	gp.message_set_subject(message, buf.subject, nil)

	--- XXX USE header_list instead and insert these? That way we don't need to do it by hand
	--- and we don't need to format etc
	if reply then
		go.object_set_header(mobj, "References", gc.references_format(reply.reference))
		go.object_set_header(mobj, "In-Reply-To", gc.references_format(reply.in_reply_to))
	end

	for k, v in pairs(opts) do
		go.object_set_header(mobj, k, v)
	end


	local body = gp.text_part_new_with_subtype("plain")
	--- XXX bad, we wan't to roll our own or maybe we can set format_opts
	gp.text_part_set_text(body, table.concat(buf.body, "\n"))
	current = body

	if attachments ~= nil and not vim.tbl_isempty(attachments) then
		local multipart = gp.multipart_new_with_subtype("mixed")
		gp.multipart_add(multipart, current)
		current = multipart
		for file, _ in pairs(attachments) do
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
