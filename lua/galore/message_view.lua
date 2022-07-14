local r = require("galore.render")
local gu = require("galore.gmime.util")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local Path = require("plenary.path")
local ui = require("galore.ui")
local nu = require("galore.notmuch-util")
local runtime = require("galore.runtime")
local browser = require("galore.browser")

local Message = Buffer:new()

local function save_attachment(attachments, filename, save_path)
	if attachments[filename] then
		-- better way to do this?
		local path = Path:new(Path:new(save_path):expand())
		if path:is_dir() then
			path = path:joinpath(filename)
		end
		gu.save_part(attachments[filename], path:expand())
		return
	end
	error("No attachment with that name")
end

--- add opts
function Message:select_attachment(cb)
	local files = vim.tbl_keys(self.state.attachments)
	vim.ui.select(files, {
		prompt = "Attachment to save:",
	}, function(item, _)
		if item then
			cb(item)
		else
			error("No file selected")
		end
	end)
end

function Message:update(line)
	self:unlock()
	self:clear()
	local message = gu.construct(line.filenames)
	-- au.process_au(message, line)
	if message then
		vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
		self.message = message
		r.show_headers(message, self.handle, { ns = self.ns }, self.line)
		self.state = r.show_message(message, self.handle, {
			ns = self.ns,
			keys = line.keys
		})
		if not vim.tbl_isempty(self.state.attachments) then
			ui.render_attachments(self.state.attachments, self)
		end
	end
	self:lock()
end

function Message:redraw(line)
	self:focus()
	self:update(line)
end

--- this crashes atm
local function mark_read(pb, line_info, vline)
	runtime.with_db_writer(function (db)
		config.values.tag_unread(db, line_info.id)
		nu.tag_if_nil(db, line_info, config.values.empty_tag)
		nu.update_line(db, pb, line_info, vline)
	end)
end

function Message:next()
	if self.vline and self.parent then
		local line_info, vline = browser.next(self.parent, self.vline)
		Message:create(line_info, "replace", self.parent, vline)
	end
end
--
function Message:prev()
	if self.vline and self.parent then
		local line_info, vline = browser.prev(self.parent, self.vline)
		Message:create(line_info, "replace", self.parent, vline)
	end
end

function Message:commands()
	vim.api.nvim_buf_create_user_command(self.handle, "GaloreSaveAttachment", function (args)
		if args.fargs then
			local save_path = "."
			if #args.fargs > 2 then
				save_path = args.fargs[2]
			end
			save_attachment(self.state.attachments, args.fargs[1], save_path)
		end
	end, {
	nargs = "*",
	complete = function ()
		return vim.tbl_keys(self.state.attachments)
	end,
	})
end

function Message:create(line, kind, parent, vline)
	Buffer.create({
		name = line.filenames[1],
		ft = "mail",
		kind = kind,
		parent = parent,
		cursor = "top",
		mappings = config.values.key_bindings.message_view,
		init = function(buffer)
			buffer.line = line
			buffer.parent = parent
			buffer.vline = vline
			buffer.ns = vim.api.nvim_create_namespace("galore-message-view")
			-- mark_read(parent, line, vline)
			buffer:update(line)
			buffer:commands()
			config.values.bufinit.message_view(buffer)
		end,
	}, Message)
end

function Message.open_attach() end

return Message
