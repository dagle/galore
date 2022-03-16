local v = vim.api
local u = require("galore.util")
local gu = require("galore.gmime.util")
local Buffer = require("galore.lib.buffer")
local job = require("galore.jobs")
local config = require("galore.config")
local reader = require("galore.reader")
local render = require("galore.render")
local Path = require("plenary.path")
local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local gs = require("galore.gmime.stream")
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")

local Compose = Buffer:new()
Compose.num = 0

-- This shouldn't control that the file exists
-- Because it might exist later on during the process of sending email
-- If you want a "safe", version wrap this one
function Compose:add_attachment(file)
	table.insert(self.attachments, file)
end

function Compose:remove_attachment()
	vim.ui.select(self.attachments, {prompt = "delete attachment"}, function (_, idx)
		if idx then
			table.remove(self.attachments, idx)
		end
	end)
end

-- this should be move to some util function
-- maybe us virtual lines to split between header and message
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
	if box.subject ~= nil then
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
	local to = gc.internet_address_list_to_string(gp.message_get_address(message, "to"), nil, false)
	local from = gc.internet_address_list_to_string(gp.message_get_address(message, "from"), nil, false)
	--- XXX add pre-hooks
	-- local message_str = gm.write_message_mem(message)
	job.send_mail_pipe(to, from, message)
	--- XXX add post-hooks
end

--- Add ability to encrypt the message
--- we then need to delete these when we load the message
--- XXX get it working
--- Are we even create a file?
--- Look up how to do filenames
function Compose:save_draft()
	vim.ui.input({
		prompt = "Save as: ",
	}, function(filename)
		local path = Path:new(config.value.draftdir, filename)
		if path:exists() then
			error("File exist")
			return
		end
		local buf = self:parse_buffer()
		local message = reader.create_message(buf, self.reply, self.attachments)
		if ret ~= nil then
			print("Failed to parse draft")
			return ret
		end
		--- should we support multiple versions?
		local id = gu.make_id(message, "draft")
		gm.set_header(message, "Message-ID", id)
		gu.insert_current_date(message)
		local ret = gm.write_message(path:expand(), message)
		if ret ~= nil then
			print("Failed to parse draft")
			return ret
		end
		nu.with_db_writer(config.values.db, function (dbwriter)
			local nm_message = nm.db_index_file(dbwriter, path:expand(), nil)
			if nm_message == nil then
				print("Failed to add draft to database")
				return ret
			end
			ret = nm.message_add_tag(nm_message, config.values.drafttag)
			if ret == nil then
				print("Failed to add tag")
				return ret
			end
		end)
		print("draft saved")
	end)
end

local function make_template(message, reply_all)
	local headers = gu.respone_headers(message, reply_all)
	local sub = gp.message_get_subject(message)
	sub = "Subject: " .. u.add_prefix(sub, "Re:")
	table.insert(headers, sub)
	return headers
end

local mark_name = "email-compose"

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
