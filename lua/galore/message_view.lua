-- When we view an email, this is the view
local v = vim.api
-- local a = require "plenary.async"
local r = require('galore.render')
local u = require("galore.util")
local nm = require("galore.notmuch")
local gm = require('galore.gmime')
local Buffer = require('galore.lib.buffer')
local conf = require('galore.config')
local Path = require('plenary.path')
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

function M._save_attachment(filename, save_path)
	-- path = path or cwd
	if M.parts[filename] then
		local path = Path:new(save_path)
		if path:is_dir() then
			path = path:joinpath(filename)
		end
		-- if path:exists() then
		-- end
		gm.save_part(M.parts[filename], path:expand())
		return
	end
	error("No attachment with that name")
end

function M.save_attach()
	-- switch to telescope later?
	vim.ui.select(M.parts, {
		prompt = "Attachment to save:"
	}, function(item, _)
		if item then
			vim.ui.input({
				prompt = "Save as:"
			}, function(path)
				M._save_attachment(item, path)
			end)
		else
			error("No file selected")
		end
	end)
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
			M.ns = vim.api.nvim_create_namespace('message-view')
			M.message = gmessage
			r.show_header(gmessage, buffer.handle, {ns = M.ns}, message)
			add_tags(message, buffer.handle)
			r.show_message(gmessage, buffer.handle, {})
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

function M.next()
end

function M.prev()
end

function M.open_attach()
end

return M
