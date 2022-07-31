local u = require("galore.util")
local ui = require("galore.ui")
local Buffer = require("galore.lib.buffer")
local job = require("galore.jobs")
local config = require("galore.config")
local builder = require("galore.builder")
local render = require("galore.render")
local gp = require("galore.gmime.parts")
local nu = require("galore.notmuch-util")
local runtime = require("galore.runtime")
local r = require("galore.render")

local Compose = Buffer:new()

function Compose:add_attachment(file)
	self.attachments[file] = true
end

function Compose:remove_attachment()
	vim.ui.select(self.attachments, {prompt = "delete attachment"}, function (_, idx)
		if idx then
			table.remove(self.attachments, idx)
		end
	end)
	self:update_attachments()
end

function Compose:set_header_option(key, value)
	self.header_opts[key] = value
end

function Compose:unset_option()
	local list = vim.tbl_keys(self.header_opts)
	vim.ui.select(list,{
		prompt = 'Option to unset',
		format_item = function (item)
			return string.format("%s = %s", item, self.header_opts[item])
		end,
	},
	function (item, _)
		if item then
			self.header_opts[item] = nil
		end
	end)
end

local function get_headers(self)
	local headers = {}
	local lines = vim.api.nvim_buf_get_lines(self.handle, 0, -1, true)
	local body_line = vim.api.nvim_buf_get_extmark_by_id(self.handle, self.ns, self.marks, {})[1]
	for i = 1, body_line do
		local start, stop = string.find(lines[i], "^%a+:")
		-- ignore lines that isn't xzy: abc
		if start ~= nil then
			local word = string.sub(lines[i], start, stop - 1)
			word = string.lower(word)
			local content = string.sub(lines[i], stop + 1)
			content = u.trim(content)
			headers[word] = {content, i}
		end
	end
	return headers, body_line
end

-- XXX Adds an empty line to body, maybe it's suppose to be like that?
function Compose:parse_buffer()
	local buf = {}
	local body = {}
	local headers, body_line = get_headers(self)
	local lines = vim.api.nvim_buf_line_count(self.handle)
	if headers.subject == nil then
		headers.subject = config.values.empty_topic
	end

	for i = body_line + 1, #lines do
		table.insert(body, lines[i])
	end
	buf.body = body
	buf.headers = headers
	return buf
end


local function get_sent_folder(sent_folder, from)
	if type(sent_folder) == "string" then
		return sent_folder
	elseif type(sent_folder) == "function" then
		return sent_folder(from)
	end
	return "sent"
end

-- Tries to send what is in the current buffer
function Compose:send(opts)
	opts = opts or {}
	local buf = self:parse_buffer()
	local message = builder.create_message(buf, opts, self.attachments, self.header_opts, builder.textbuilder)
	if not message then
		return
	end
	if config.values.pree_hooks then
		config.values.pree_hooks(message)
	end
	job.send_mail(message)
	-- we should try to figure out the sent folder from the message
	-- local folder = get_sent_folder(config.values.sent_folder, buf.from)
	-- job.insert_mail(message, folder, config.values.sent_tags)
	--- change the the old tag
	if self.in_reply_to then
		runtime.with_db_writer(function(db)
			nu.change_tag(db, self.reply.in_reply_to, "+replied")
		end)
	end
	job.insert_mail(message, config.values.draftdir, "+sent")
	if config.values.pree_hooks then
		config.values.post_hooks(message)
	end
	self:set_option("modified", false)
end

function Compose:preview(kind, opts)
	kind = kind or "floating"
	opts = opts or {}
	local buf = self:parse_buffer()

	local message = builder.create_message(buf, opts, self.attachments, self.header_opts, builder.textbuilder)
	Buffer.create({
		kind = kind,
		ft = "mail",
		init = function (buffer)
			buffer.ns = vim.api.nvim_create_namespace("galore-message-view")
			mime_view(buffer.handle, message, {ns=buffer.ns})
		end
	}, nil)
end

function Compose:save_draft(opts)
	opts = opts or {}
	local buf = self:parse_buffer()
	if config.values.draftencrypt and config.values.gpg_id then
		opts.encrypt = true
		opts.recipients = config.values.gpg_id
	end
	local message = builder.create_message(buf, opts, self.attachments, self.header_opts, builder.textbuilder)
	if not message then
		return
	end
	if ret ~= nil then
		print("Failed to parse draft")
		return ret
	end
	job.insert_mail(message, config.values.draftdir, "+draft")
end

local function make_template(message, reply_all)
	local response = gu.respone_headers(message, reply_all)
	local sub = gp.message_get_subject(message)
	sub = "Subject: " .. u.add_prefix(sub, "Re:")
	table.insert(response, sub)
	return response
end

function Compose:update_attachments()
	vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
	ui.render_attachments(self.attachments, self)
end

function Compose:delete_tmp()
	-- vim.fn.delete()
end

local function addfiles(self, files)
	if not files then
		return
	end
	if type(files) == "string" then
		self:add_attachment(files)
		return
	end
	for _, file in ipairs(files) do
		self:add_attachment(file)
	end
end

local function make_seperator(buffer, lines)
	buffer.ns = vim.api.nvim_create_namespace("galore-compose")

	local line_num = lines
	local col_num = 0

	local virt_lines = {
		virt_lines = { { { "Email body", "GaloreSeperator" } } },
	}
	buffer.marks = buffer:set_extmark(buffer.ns, line_num, col_num, virt_lines)
end

function Compose:commands()
	vim.api.nvim_buf_create_user_command(self.handle, "GaloreAddAttachment", function (args)
		if args.fargs then
			for _, value in ipairs(args.fargs) do
				self:add_attachment(value)
			end
			self:update_attachments()
		end
	end, {
	nargs = "*",
	complete = "file"
})
end

function Compose:update()
	self:clear()
	r.show_headers(self.message, self.handle, nil, nil)
	local after = vim.fn.line('$') - 1
	self.state = r.show_message(self.message, self.handle, self.opts)

	make_seperator(self.handle, after)

	if not vim.tbl_isempty(self.attachments) then
		ui.render_attachments(self.attachments, self)
	end
end

-- change message to file
function Compose:create(kind, old_message, header_opts, opts)
	opts = opts or {}
	header_opts = header_opts or {}
	-- local template
	-- this sucks
	local message = tm.default_template()
	if old_message then
		tm.response_message(message, old_message, opts.response_mode)
	else
		tm.compose_new(message, opts.mailto)
	end
	Buffer.create({
		name = vim.fn.tempname(),
		ft = "mail",
		kind = kind,
		cursor = "top",
		buftype = "",
		modifiable = true,
		mappings = config.values.key_bindings.compose,
		init = function(buffer)
			buffer.message = message
			buffer.opts = opts
			addfiles(buffer, opts.attach)
			buffer.header_opts = header_opts
			buffer.ns = vim.api.nvim_create_namespace("galore-compose")
			buffer.dians = vim.api.nvim_create_namespace("galore-dia")
			buffer:update()

			buffer:set_option("modified", false)

			config.values.bufinit.compose(buffer)
			buffer:update_attachments()
		end,
	}, Compose)
end

return Compose
