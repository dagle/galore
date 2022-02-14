local v = vim.api
local u = require("galore.util")
-- local nm = require("galore.notmuch")
local gm = require("galore.gmime")
local gu = require("galore.gmime-util")
local Buffer = require("galore.lib.buffer")
local job = require("galore.jobs")
-- local path = require('plenary.path')
local config = require("galore.config")
local reader = require("galore.reader")
local render = require("galore.render")
local Path = require("plenary.path")
local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")

local M = {}

M.attachments = {}

M.sent = {}

--- We need a remove function
function M.add_attachment(file)
	table.insert(M.attachments, file)
end

function M.remove_attachment()
	vim.ui.select(M.attachments, {prompt = "delete attachment"}, function (_, idx)
		if idx then
			table.remove(M.attachments, idx)
		end
	end)
end

-- this should be move to some util function
-- maybe us virtual lines to split between header and message
function M.parse_buffer()
	local box = {}
	local body = {}
	local lines = v.nvim_buf_get_lines(0, 0, -1, true)
	local body_line = vim.api.nvim_buf_get_extmark_by_id(M.compose.handle, M.ns, M.marks, {})[1]
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
function M.send_message()
	-- should check for nil
	local buf = M.parse_buffer()
	local message = reader.create_message(buf, M.reply, M.attachments)
	local to = gm.show_addresses(gm.message_get_address(message, "to"))
	local from = gm.show_addresses(gm.message_get_address(message, "from"))
	--- XXX add pre-hooks
	local message_str = gm.write_message_mem(message)
	job.send_mail(to, from, message_str)
	--- XXX add post-hooks
end

--- Add ability to encrypt the message
--- we then need to delete these when we load the message
function M.save_draft()
	vim.ui.input({
		prompt = "Save as: ",
	}, function(filename)
		local path = Path:new(config.value.draftdir, filename)
		if path:exists() then
			error("File exist")
			return
		end
		local buf = M.parse_buffer()
		local message = reader.create_message(buf, M.ref, M.attachments)
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
	local sub = gm.message_get_subject(message)
	sub = "Subject: " .. u.add_prefix(sub, "Re:")
	table.insert(headers, sub)
	return headers
end

local mark_name = "email-compose"

function M.create(kind, message, reply)
	local template
	-- local ref = util.get_ref()
	if message then
		template = make_template(message)
	else
		template = u.default_template()
	end
	-- if M.compose then
	-- M.compose:focus()
	-- return
	-- end
	-- try to find a buffer first
	Buffer.create({
		name = "galore-compose",
		ft = "mail",
		kind = kind,
		cursor = "top",
		modifiable = true,
		mappings = config.values.key_bindings.compose,
		init = function(buffer)
			M.compose = buffer
			M.message = message
			M.reply = reply

			-- this is a bit meh
			M.ns = vim.api.nvim_create_namespace("email-compose")

			local line_num = #template
			local col_num = 0

			local opts = {
				virt_lines = { { { "Email body", "Comment" } } },
			}
			M.compose:clear()

			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, template)
			if message then
				render.show_message(message, buffer.handle, { reply = true })
			end
			M.marks = buffer:set_extmark(M.ns, line_num, col_num, opts)
		end,
	})
end

return M
