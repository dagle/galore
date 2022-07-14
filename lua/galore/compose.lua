local u = require("galore.util")
local ui = require("galore.ui")
local Buffer = require("galore.lib.buffer")
local job = require("galore.jobs")
local config = require("galore.config")
local builder = require("galore.builder")
local render = require("galore.render")
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local ge = require("galore.gmime.crypt")
local gu = require("galore.gmime.util")
local nu = require("galore.notmuch-util")
local runtime = require("galore.runtime")
local ffi = require("ffi")

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

local extra_headers = {
	-- ["Return-Path"] = u.id,
	-- ["Reply-To"] = u.id,
	["References"] = gc.references_format,
	["In-Reply-To"] = gc.references_format,
}

function Compose:set_header_option(key, value)
	-- should we really guard this?
	if extra_headers[key] then
		local formated = extra_headers[key](value)
		if formated then
			self.header_opts[key] = formated
			return
		end
		return
	end
	self.header_opts[key] = value
end

local function make_options(self, opts)
	if opts then
		for key, value in pairs(opts) do
			self:set_header_option(key, value)
		end
	end
end

-- this is bad
-- function Compose:set_option_menu()
-- 	local list = vim.tbl_keys(extra_headers)
-- 	vim.ui.select(list,{
-- 		prompt = 'Value to set',
-- 		format_item = function (item)
-- 			return string.format("%s = %s", item, self.header_opts[item] or "")
-- 		end,
-- 	},
-- 	function (item, _)
-- 		if item then
-- 			vim.ui.input(string.format("Value for %s: ", item),
-- 			function (input)
-- 				if input then
-- 					self:set_header_option(item, input)
-- 				end
-- 			end)
-- 		end
-- 	end)
-- end

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
			headers[word] = content
		end
	end
	return headers, body_line
end

-- XXX Adds an empty line to body, maybe it's suppose to be like that?
function Compose:parse_buffer()
	local body = {}
	local box, body_line = get_headers(self)
	local lines = vim.api.nvim_buf_line_count(self.handle)
	if box.subject == nil then
		box.subject = config.values.empty_topyic
	end

	for i = body_line + 1, #lines do
		table.insert(body, lines[i])
	end
	box.body = body
	return box
end

--- address = boolean
local key_cache = {}

local function check_encrypted(self)
	local headers = get_headers(self)
	if vim.tbl_isempty(headers) then
		return false
	end

	--- We need to track that we atleast have a to header
	local ctx = ge.get_gpg_ctx()
	for key, value in pairs(headers) do
		if key_cache[value] == nil then
			if key == "cc" or key == "bcc" or key == "to" then
				local addrs = gc.internet_address_list_parse(runtime.parser_opts, value)
				for addr in gu.internet_address_list_iter(addrs) do
					if gc.internet_address_is_mailbox(addr) then
						local mb = ffi.cast("InternetAddressMailbox *", addr)
						local name = gc.internet_address_get_name(addr)
						local email = gc.internet_address_mailbox_get_addr(mb)
						if ge.gpg_key_exists(ctx, name, false) or ge.gpg_key_exists(ctx, email, false) then
							key_cache[value] = true
						else
							key_cache[value] = false
							return false
						end
					end
					--- XXX add support for email groups?
				end
			end
		elseif key_cache[value] == false then
			return false
		end
	end
	return true
end

--- Can we do this without autocrypt too?
function Compose:notify_encrypted()
	local enc = check_encrypted(self)
	if enc then
		vim.b.galore_encrypt = "🔑"
	else
		--- we clear it if not
		vim.b.galore_encrypt = nil
	end
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
		nu.change_tag(self.reply.in_reply_to, "+replied")
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
	if not vim.tbl_isempty(self.attachments) then
		ui.render_attachments(self.attachments, self)
	end
end

function Compose:delete_tmp()
	-- vim.fn.delete()
end

local function addfiles(files)
	if not files then
		return
	end
	if type(files) == "string" then
		Compose:add_attachment(files)
		return
	end
	for _, file in ipairs(files) do
		Compose:add_attachment(file)
	end
end

local function make_seperator(buffer, lines)
	buffer.ns = vim.api.nvim_create_namespace("galore-compose")

	local line_num = lines
	local col_num = 0

	local virt_lines = {
		virt_lines = { { { "Email body", "GaloreSeperator" } } },
	}
	buffer:set_extmark(buffer.ns, line_num, col_num, virt_lines)
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

-- change message to file
function Compose:create(kind, message, header_opts, opts)
	opts = opts or {}
	header_opts = header_opts or {}
	local template
	-- this sucks
	if message and opts.reply then
		template = make_template(message, opts.response_mode)
	elseif message then
		-- this should just "copy" the email-headers that we have set
		template = make_template(message, opts.response_mode)
	else
		template = u.default_template(opts.mailto)
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
			buffer.attachments = addfiles(opts.attach)
			buffer.header_opts = {}
			make_options(buffer, header_opts)
			buffer:clear()

			buffer:set_lines(0, 0, true, template)
			if message then
				render.show_message(message, buffer.handle, opts)
			end
			make_seperator(buffer, #template)
			buffer:set_option("modified", false)

			config.values.bufinit.compose(buffer)
		end,
	}, Compose)
end

return Compose
