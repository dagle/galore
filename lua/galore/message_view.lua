local v = vim.api
local r = require("galore.render")
local u = require("galore.util")
local gu = require("galore.gmime.util")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local Path = require("plenary.path")
local ui = require("galore.ui")

local Message = Buffer:new()
Message.num = 0

local function _view_attachment(self, filename, kind)
	kind = kind or "floating"
	if self.attachments[filename] then
		if self.attachments[filename][2] then
			Buffer.create({
				name = filename,
				ft = require("plenary.filetype").detect(filename),
				kind = kind,
				-- ref = ref,
				cursor = "top",
				init = function(buffer)
					local content = u.format(gu.part_to_buf(self.attachments[filename][1]))
					v.nvim_buf_set_lines(buffer.handle, 0, 0, true, content)
					v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
				end,
			})
		else
			-- pipe this some good way etc
			-- config.values.external_view
			return
		end
	end
	-- print("No attachment with that name")
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
		gu.save_part(self.attachments[filename][1], path:expand())
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


function Message:update(filename)
	self:unlock()
	self:clear()
	local gmessage = gu.parse_message(filename)
	if gmessage then
		if self.ns then
			vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
		end
		self.ns = vim.api.nvim_create_namespace("galore-message-view")
		self.message = gmessage
		r.show_header(gmessage, self.handle, { ns = self.ns }, self.line)
		self.attachments = r.show_message(gmessage, self.handle, {ns = self.ns})
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

function Message:next()
	local line, vline = self.parent:next(self.vline)
	Message:create(line, "replace", self.parent, vline)
end
--
function Message:prev()
	local line, vline = self.parent:prev(self.vline)
	Message:create(line, "replace", self.parent, vline)
end

function Message:create(line, kind, parent, vline)
	Buffer.create({
		name = "galore-view: " .. line.filename,
		ft = "mail",
		kind = kind,
		parent = parent,
		cursor = "top",
		mappings = config.values.key_bindings.message_view,
		init = function(buffer)
			buffer.line = line
			buffer.parent = parent
			buffer.vline = vline
			buffer:update(line.filename)
		end,
	}, Message)
end

function Message.open_attach() end

return Message
