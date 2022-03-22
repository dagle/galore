local v = vim.api
local u = require("galore.util")
local gu = require("galore.gmime.util")
local ui = require("galore.ui")
local Buffer = require("galore.lib.buffer")
local job = require("galore.jobs")
local config = require("galore.config")
local reader = require("galore.reader")
local render = require("galore.render")
local go = require("galore.gmime.object")
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local ffi = require("ffi")
local runtime = require("galore.runtime")

local Compose = Buffer:new()
Compose.num = 0

-- This shouldn't control that the file exists
-- Because it might exist later on during the process of sending email
-- If you want a "safe", version wrap this one
function Compose:add_attachment(file)
	table.insert(self.attachments, file)
	self:update_attachments()
end

function Compose:remove_attachment()
	vim.ui.select(self.attachments, {prompt = "delete attachment"}, function (_, idx)
		if idx then
			table.remove(self.attachments, idx)
		end
	end)
	self:update_attachments()
end

-- this should be move to some util function
-- maybe us virtual lines to split between header and message
-- XXX Adds an empty line to body
function Compose:parse_buffer()
	local box = {}
	local body = {}
	local lines = v.nvim_buf_get_lines(0, 0, -1, true)
	local body_line = vim.api.nvim_buf_get_extmark_by_id(self.handle, self.ns, self.marks, {})[1]
	for i = 1, body_line do
		local start, stop = string.find(lines[i], "^%a+:")
		-- ignore lines that isn't xzy: abc
		if start ~= nil then
			local word = string.sub(lines[i], start, stop - 1)
			word = string.lower(word)
			local content = string.sub(lines[i], stop + 1)
			content = u.trim(content)
			box[word] = content
		end
	end
	if box.subject == nil then
		box.subject = config.values.empty_topyic
	end

	for i = body_line + 1, #lines do
		table.insert(body, lines[i])
	end
	box.body = body
	return box
end

-- Tries to send what is in the current buffer
function Compose:send()
	-- should check for nil
	local buf = self:parse_buffer()
	local message = reader.create_message(buf, self.reply, self.attachments)
	local to = gc.internet_address_list_to_string(gp.message_get_address(message, "to"), runtime.format_opts, false)
	local from = gc.internet_address_list_to_string(gp.message_get_address(message, "from"), runtime.format_opts, false)
	--- XXX add pre-hooks
	-- local message_str = gm.write_message_mem(message)
	job.send_mail_pipe(to, from, message)
	--- XXX add post-hooks
end

function Compose:save_draft(filename)
	if filename == nil then
		return
	end
	local buf = self:parse_buffer()
	local message = reader.create_message(buf, self.reply, self.attachments)
	if ret ~= nil then
		print("Failed to parse draft")
		return ret
	end
	local id = gu.make_id(message)
	go.object_set_header(ffi.cast("GMimeObject *", message), "Message-ID", id)
	gu.insert_current_date(message)
	job.insert_mail(message, config.values.draftdir, config.values.drafttags)
end

local function make_template(message, reply_all)
	local headers = gu.respone_headers(message, reply_all)
	local sub = gp.message_get_subject(message)
	sub = "Subject: " .. u.add_prefix(sub, "Re:")
	table.insert(headers, sub)
	return headers
end

local mark_name = "email-compose"

function Compose:update_attachments()
	if not vim.tbl_isempty(self.attachments) then
		ui.render_attachments2(self.attachments, self)
	end
end

function Compose:create(kind, message, reply)
	self.num = self.num + 1
	local template
	-- local ref = util.get_ref()
	if message then
		template = make_template(message)
	else
		template = u.default_template()
	end
	Buffer.create({
		--- XXX maybe we shouldn't name it
		name = "galore-compose",
		ft = "mail",
		kind = kind,
		cursor = "top",
		modifiable = true,
		mappings = config.values.key_bindings.compose,
		init = function(buffer)
			buffer.message = message
			buffer.reply = reply
			buffer.attachments = {}

			-- this is a bit meh
			buffer.ns = vim.api.nvim_create_namespace("email-compose")

			local line_num = #template
			local col_num = 0

			local opts = {
				virt_lines = { { { "Email body", "Comment" } } },
			}
			buffer:clear()

			-- v.nvim_buf_set_lines(buffer.handle, 0, 0, true, template)
			buffer:set_lines(0, 0, true, template)
			if message then
				render.show_message(message, buffer.handle, { reply = true })
			end
			buffer.marks = buffer:set_extmark(buffer.ns, line_num, col_num, opts)
		end,
	}, Compose)
end

return Compose
