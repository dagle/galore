-- When we view an email, this is the view
local v = vim.api
-- local a = require "plenary.async"
local r = require('galore.render')
local u = require("galore.util")
local nm = require("galore.notmuch")
local gm = require('galore.gmime')
local Buffer = require('galore.lib.buffer')
local conf = require('galore.config')
-- local attach_view = require('galore.attach_view')
local M = {}

M.state = {}

-- how do we name parts etc?
-- for now, parts is just attachments
M.parts = {}

local function view_attachment(filename, kind)
	kind = kind or conf.values.attachment_preview
	if M.parts[filename] then
		-- XXX
		-- check if the file is viewable
		if u.viewable(M.parts[filename]) then
			-- attach_view.create(M.attachment[filename], kind)
		else
			error("File not viewable")
			return
		end
	end
	error("No attachment with that name")
end

function M.save_attachment(filename, save_path)
	if M.parts[filename] then
		local path
		if u.is_absolute(save_path) then
			path = save_path
		else
			save_path = save_path or ""
			path = conf.values.save_path .. save_path
		end
		if is_directory(path) then
			path = path .. filename
		end
		gm.save_part(M.parts[filename], path)
		return
	end
	error("No attachment with that name")
end

local function add_tags(message, buffer)
	M.ns = vim.api.nvim_create_namespace('message-tags')
	local tags = table.concat(u.collect(nm.message_get_tags(message)), " ")
	local str = "(" .. tags .. ")"

	local line_num = 0
	local col_num = 0

	local opts = {
		virt_text = {{str, "Comment"}},
	}
	M.marks = vim.api.nvim_buf_set_extmark(buffer, M.ns, line_num, col_num, opts)
end

function M.update(message)
	if not M.message_view_buffer then
		return
	end
	local buffer = M.message_view_buffer
	vim.api.nvim_buf_set_option(buffer.handle, "modifiable", true)
	M.message_view_buffer:clear()
	local filename = nm.message_get_filename(message)
	-- if filename or filename ~= "" then
	if filename then
		local gmessage = gm.parse_message(filename)
		if gmessage then
			M.message = gmessage
			r.show_header(gmessage, buffer.handle)
			add_tags(message, buffer.handle)
			r.show_message(gmessage, buffer.handle, false)
			vim.api.nvim_buf_set_option(buffer.handle, "modifiable", false)
		end
	end
end

-- TODO: How do we make it so it's not global? But still feel nice
-- should do messages instead of 1 message?
-- that way it works for threads and single messages
function M.create(message, kind, ref)
	M.state = message

	if M.message_view_buffer then
		M.message_view_buffer:focus()
		M.update(message)
		return
	end
	-- try to find a buffer first
	Buffer.create {
		name = "galore-message",
		ft = "mail",
		kind = kind,
		ref = ref,
		cursor = "top",
		init = function(buffer)
			M.message_view_buffer = buffer
			M.update(message)

			for bind, func in pairs(conf.values.key_bindings.message_view) do
				v.nvim_buf_set_keymap(buffer.handle, 'n', bind, func, { noremap=true, silent=true })
			end
		end,
	}
end

function M.close()
	M.message_view_buffer:close(true)
	M.message_view_buffer = nil
end

function M.message_ref()
	return M.message
end

-- local function ppMail(message)
-- 	print(message.get_path())
-- end

-- function M.show_message(settings, thread)
	-- local messages = thread:get_messages()
	-- for _, message in ipairs(messages) do
	-- 	local file = messages.get_path(message)
	-- 	-- feed this into gmime?
	-- 	for line in io.lines(file) do
	-- 		print(line)
	-- 	end
	-- 	-- print(ppMail())
	-- end
	-- -- print(vim.inspect(thread:get_messages()))
-- end

function M.next()
end

function M.prev()
end

function M.open_attach()
end

function M.save_attach()
end

return M
