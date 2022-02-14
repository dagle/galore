-- When we view an email, this is the view
local v = vim.api
-- local a = require "plenary.async"
local r = require("galore.render")
local u = require("galore.util")
local nm = require("galore.notmuch")
local gm = require("galore.gmime")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local Path = require("plenary.path")
-- local attach_view = require('galore.attach_view')
local M = {}

M.state = {}

-- how do we name parts etc?
-- for now, parts is just attachments
M.attachments = {}

local function _view_attachment(filename, kind)
	kind = kind or "floating"
	if M.attachments[filename] then
		if M.attachments[filename][2] then
			Buffer.create({
				name = filename,
				ft = require("plenary.filetype").detect(filename),
				kind = kind,
				-- ref = ref,
				cursor = "top",
				init = function(buffer)
					local content = u.format(gm.part_to_buf(M.attachments[filename][1]))
					v.nvim_buf_set_lines(buffer.handle, 0, 0, true, content)
					v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
				end,
			})
			-- attach_view.create(M.attachment[filename], kind)
		else
			error("File not viewable")
			return
		end
	end
	print("No attachment with that name")
end

function M.raw_mode(kind)
	kind = kind or "floating"
	Buffer.create({
		name = M.state,
		-- name = "raw_mode",
		ft = "mail",
		kind = "floating",
		-- ref = ref,
		cursor = "top",
		init = function(buffer)
			-- need a way to open files in a float
			vim.cmd(":e " .. M.state)
			-- vim.api.nvim_set_keymap('n', 'q', "", nil)
		end,
	})
end

function M._save_attachment(filename, save_path)
	if M.attachments[filename] then
		-- better way to do this?
		local path = Path:new(Path:new(save_path):expand())
		if path:is_dir() then
			path = path:joinpath(filename)
		end
		gm.save_part(M.attachments[filename][1], path:expand())
		return
	end
	error("No attachment with that name")
end

function M.view_attachment()
	local files = u.collect_keys(M.attachments)
	vim.ui.select(files, {
		prompt = "View attachment:",
	}, function(item, _)
		if item then
			_view_attachment(item)
		else
			error("No file selected")
		end
	end)
end

function M.save_attach()
	-- switch to telescope later?
	local files = u.collect_keys(M.attachments)
	vim.ui.select(files, {
		prompt = "Attachment to save:",
	}, function(item, _)
		if item then
			vim.ui.input({
				-- we want to have hints
				prompt = "Save as: ",
			}, function(path)
				M._save_attachment(item, path)
			end)
		else
			error("No file selected")
		end
	end)
end

function M.update(file)
	if not M.message_view_buffer then
		return
	end
	local buffer = M.message_view_buffer
	buffer:unlock()
	M.message_view_buffer:clear()
	local gmessage = gm.parse_message(file)
	if gmessage then
		M.ns = vim.api.nvim_create_namespace("galore-message-view")
		M.message = gmessage
		-- r.show_header(gmessage, buffer.handle, { ns = M.ns }, message)
		r.show_header(gmessage, buffer.handle, nil, file)
		M.attachments = r.show_message(gmessage, buffer.handle, {})
	end
	buffer:lock()
end

local function redraw(file)
	M.message_view_buffer:focus()
	-- this is bad
	vim.api.nvim_buf_clear_namespace(M.message_view_buffer.handle, M.ns, 0, -1)
	M.update(file)
end

-- TODO: How do we make it so it's not global? But still feel nice
-- should do messages instead of 1 message?
-- that way it works for threads and single messages
function M.create(file, kind, parent)
	M.state = file

	if M.message_view_buffer then
		redraw(file)
		return
	end
	-- try to find a buffer first
	Buffer.create({
		name = "galore-message",
		ft = "mail",
		kind = kind,
		parent = parent,
		cursor = "top",
		mappings = config.values.key_bindings.message_view,
		init = function(buffer)
			M.message_view_buffer = buffer
			M.update(file)
		end,
	})
end

function M.close()
	M.message_view_buffer:close(true)
	M.message_view_buffer = nil
end

function M.message_ref()
	return M.message
end

-- function M.next()
-- 	local message = M.message_view_buffer.parent:next()
-- 	redraw(message)
-- end
--
-- function M.prev()
-- 	local message = M.message_view_buffer.parent:prev()
-- 	redraw(message)
-- end

function M.open_attach() end

return M
