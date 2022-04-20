local r = require("galore.render")
local u = require("galore.util")
local gu = require("galore.gmime.util")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local Path = require("plenary.path")
local ui = require("galore.ui")
local nu = require("galore.notmuch-util")
local pv = require("galore.part_view")
local gp = require("galore.gmime.parts")

local Message = Buffer:new()
Message.num = 0

local function _view_attachment(self, filename, kind)
	kind = kind or "floating"
	if self.attachments[filename] then
		pv.create(self.attachments[filename], filename, require("plenary.filetype").detect(filename))
	end
end

function Message:raw_mode(kind)
	Buffer.create({
		name = self.line.filename,
		ft = "mail",
		kind = kind or "floating",
		cursor = "top",
		init = function(buffer)
			vim.cmd(":e " .. self.line.filename)
		end,
	})
end

function Message:_save_attachment(filename, save_path)
	if self.attachments[filename] then
		-- better way to do this?
		local path = Path:new(Path:new(save_path):expand())
		if path:is_dir() then
			path = path:joinpath(filename)
		end
		gu.save_part(self.attachments[filename], path:expand())
		return
	end
	error("No attachment with that name")
end

function Message:view_attach()
	local files = u.collect_keys(self.attachments)
	vim.ui.select(files, {
		prompt = "View attachment:",
	}, function(item, _)
		if item then
			_view_attachment(self, item, "floating")
		else
			error("No file selected")
		end
	end)
end

function Message:save_attach()
	-- switch to telescope later?
	local files = u.collect_keys(self.attachments)
	vim.ui.select(files, {
		prompt = "Attachment to save:",
	}, function(item, _)
		if item then
			vim.ui.input({
				-- we want to have hints
				prompt = "Save as: ",
			}, function(path)
				self:_save_attachment(item, path)
			end)
		else
			error("No file selected")
		end
	end)
end

function Message:update(filenames)
	self:unlock()
	self:clear()
	local message = gu.construct(filenames)
	if message then
		if self.ns then
			vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
		end
		self.ns = vim.api.nvim_create_namespace("galore-message-view")
		self.message = message
		r.show_header(message, self.handle, { ns = self.ns }, self.line)
		self.attachments = r.show_message(message, self.handle, {ns = self.ns})
		if not vim.tbl_isempty(self.attachments) then
			ui.render_attachments(self.attachments, self)
		end
	end
	self:lock()
end

function Message:redraw(filename)
	self:focus()
	self:update(filename)
end

local function make_read(browser, line_info, vline)
	config.values.tag_unread(line_info.id)
	nu.tag_if_nil(line_info, config.values.empty_tag)
	nu.update_line(browser, line_info, vline)
end


function Message:next()
	if self.vline then
		local vline, line_info = self.parent:next(self.vline)
		Message:create(line_info, "replace", self.parent, vline)
	end
end
--
function Message:prev()
	if self.vline then
		local vline, line_info = self.parent:prev(self.vline)
		Message:create(line_info, "replace", self.parent, vline)
	end
end

--- Makes a movement in parent etc
function Message:move()
end

function Message:create(line, kind, parent, vline)
	Buffer.create({
		name = "galore-view: " .. line.filenames[1],
		ft = "mail",
		kind = kind,
		parent = parent,
		cursor = "top",
		mappings = config.values.key_bindings.message_view,
		init = function(buffer)
			buffer.line = line
			buffer.parent = parent
			buffer.vline = vline
			make_read(parent, line, vline)
			buffer:update(line.filenames)
		end,
	}, Message)
end

function Message.open_attach() end

return Message
