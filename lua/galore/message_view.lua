-- When we view an email, this is the view
local v = vim.api
local r = require("galore.render")
local u = require("galore.util")
local gu = require("galore.gmime.util")
local Buffer = require("galore.lib.buffer")
local config = require("galore.config")
local Path = require("plenary.path")
local Message = Buffer:new()

-- Message.state = {}
Message.num = 0

local function _view_attachment(filename, kind)
	kind = kind or "floating"
	if Message.attachments[filename] then
		if Message.attachments[filename][2] then
			Buffer.create({
				name = filename,
				ft = require("plenary.filetype").detect(filename),
				kind = kind,
				-- ref = ref,
				cursor = "top",
				init = function(buffer)
					local content = u.format(gm.part_to_buf(Message.attachments[filename][1]))
					v.nvim_buf_set_lines(buffer.handle, 0, 0, true, content)
					v.nvim_buf_set_lines(buffer.handle, -2, -1, true, {})
				end,
			})
		else
			error("File not viewable")
			return
		end
	end
	print("No attachment with that name")
end

function Message:raw_mode(kind)
	Buffer.create({
		name = self.file,
		-- name = "raw_mode",
		ft = "mail",
		kind = kind or "floating",
		-- ref = ref,
		cursor = "top",
		init = function(buffer)
			vim.cmd(":e " .. self.file)
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

function Message:view_attachment()
	local files = u.collect_keys(self.attachments)
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

function Message:update(file)
	self:unlock()
	self:clear()
	local gmessage = gu.parse_message(file)
	if gmessage then
		self.ns = vim.api.nvim_create_namespace("galore-message-view")
		self.message = gmessage
		-- r.show_header(gmessage, buffer.handle, { ns = M.ns }, message)
		r.show_header(gmessage, self.handle, nil, file)
		self.attachments = r.show_message(gmessage, self.handle, {})
		if next(self.attachments) then
			local marks = {}
			for k, _ in pairs(self.attachments) do
				local str = string.format("-[%s]", k)
				table.insert(marks, {str, "Comment"})
			end
			local line = vim.fn.line("$") - 1
			local opts = {
				virt_lines = {
					marks
				},
			}
			self:set_extmark(self.ns, line, 0, opts)
		end
	end
	self:lock()
end

function Message:redraw(file)
	self:focus()
	self:update(file)
end

function Message:next()
	local file, vline = self.parent:next(self.vline)
	self.vline = vline
	self:redraw(file)
end
--
function Message:prev()
	local file, vline = self.parent:prev(self.vline)
	self.vline = vline
	self:redraw(file)
end

function Message:create(file, kind, parent, vline)
	self.num = self.num + 1
	Buffer.create({
		name = u.gen_name("galore-message", self.num),
		ft = "mail",
		kind = kind,
		parent = parent,
		cursor = "top",
		mappings = config.values.key_bindings.message_view,
		init = function(buffer)
			buffer.file = file
			buffer.parent = parent
			buffer.vline = vline
			buffer:update(file)
		end,
	}, Message)
end

function Message.open_attach() end

return Message
