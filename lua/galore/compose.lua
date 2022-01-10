local v = vim.api
local u = require("galore.util")
-- local nm = require("galore.notmuch")
local gm = require('galore.gmime')
local gu = require('galore.gmime-util')
local Buffer = require('galore.lib.buffer')
local job = require('galore.jobs')
-- local path = require('plenary.path')
local conf = require('galore.config')
local reader = require('galore.reader')
local render = require('galore.render')
local Path = require "plenary.path"

local M = {}

M.attachments = {}

function M.add_attachment(file)
	-- check that compose is opened
	-- check that the file actually exist
	table.insert(M.attachments, file)
end

-- this should be move to some util function
-- maybe us virtual lines to split between header and message
-- FIXME: Convert all keys to lower etc, shouldn't force people to write
-- To: instead of to:
function M.parse_buffer()
	local box = {}
	local body = {}
	local lines = v.nvim_buf_get_lines(0, 0, -1, true)
	local body_line = vim.api.nvim_buf_get_extmark_by_id(M.compose.handle, M.ns, M.marks, {})[1]
	for i = 1,body_line do
		local start, stop = string.find(lines[i], "^%a+:")
		-- ignore lines that isn't xzy: abc
		if start ~= nil then
			local word = string.sub(lines[i], start, stop-1)
			local content = string.sub(lines[i], stop+1)
			content = u.trim(content)
			box[word] = content
		end
	end

	for i = body_line+1, #lines do
		table.insert(body, lines[i])
	end
	box.body = body
	return box
end

-- Tries to send what is in the current buffer
function M.send_message()
	-- should check for nil
	local buf = M.parse_buffer()
	local ref
	if M.is_reply and M.message then
		ref = u.make_ref(M.message)
	else
		ref = u.get_ref(M.message)
	end
	local message = reader.create_message(buf, ref, M.attachments)
	local to = gm.show_addresses(gm.message_get_address(message, 'to'))
	local from = gm.show_addresses(gm.message_get_address(message, 'from'))
	local message_str = gm.write_message_mem(message)
	job.send_mail(to, from, message_str)
end

function M.save_draft()
	vim.ui.input({
		prompt = "Save as: ",
	},
	function(filename)
		-- should warn if you overwrite a file
		-- path:new(filename)
		local file = u.save_path(filename, conf.values.drafts)
		local p = Path:new(file)
		if p:exists() then
			-- write an error
			return
		end
		local message = reader.create_message(M.ref, M.attachments)
		gm.write_message(file, message)
		print("draft saved")
	end
	)
end

local function make_template(message, reply_all)
	local headers = gu.respone_headers(message, reply_all)
	local sub = gm.message_get_subject(message)
	sub = "Subject: " .. u.add_prefix(sub, "Re:")
	table.insert(headers, sub)
	return headers
end


-- this should also not be global
function M.create(kind, message, is_reply)
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
	Buffer.create {
		name = "galore-compose",
		ft = "mail",
		kind = kind,
		cursor = "top",
		modifiable = true,
		-- shouldn't be a wipeable?
		-- ref = ref,
		init = function(buffer)
			M.compose = buffer
			M.message = message
			M.is_reply = is_reply

			-- this is a bit meh
			M.ns = vim.api.nvim_create_namespace('email-compose')

			local line_num = #template
			local col_num = 0

			local opts = {
				virt_lines = {{{"Email body", "Comment"}}},
			}
			M.compose:clear()

			v.nvim_buf_set_lines(buffer.handle, 0, 0, true, template)
			if message then
				render.show_message(message, buffer.handle, {reply = true})
			end
			M.marks = vim.api.nvim_buf_set_extmark(buffer.handle, M.ns, line_num, col_num, opts)
			for bind, func in pairs(conf.values.key_bindings.compose) do
				v.nvim_buf_set_keymap(buffer.handle, 'n', bind, func, { noremap=true, silent=true })
			end
			-- local buf = M.parse_buffer()
			-- P(buf)
			-- local mes = r.create_message(buf, reply, nil)
			-- gm.write_message("/home/dagle/test.eml", mes)
			-- local mes = M.create_message(reply, {"/home/dagle/tinywl.c"})
			-- gm.write_message("/home/dagle/test_email", mes)
		end,
	}
end

return M
