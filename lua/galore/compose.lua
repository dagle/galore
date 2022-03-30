local v = vim.api
local u = require("galore.util")
local gu = require("galore.gmime.util")
local ui = require("galore.ui")
local Buffer = require("galore.lib.buffer")
local job = require("galore.jobs")
local config = require("galore.config")
local builder = require("galore.builder")
local render = require("galore.render")
local gp = require("galore.gmime.parts")
local nu = require("galore.notmuch-util")

local Compose = Buffer:new()
Compose.num = 0

-- This shouldn't control that the file exists
-- Because it might exist later on during the process of sending email
-- If you want a "safe", version wrap this one
function Compose:add_attachment(file)
	self.attachments[file] = true
	self:update_attachments()
end

function Compose:remove_attachment()
	vim.ui.select(self.attachments, {prompt = "delete attachment"}, function (_, idx)
		if idx then
			table.remove(self.attachments, idx)
		end
	end)
	self:update_attachments()
end

local function nop(value)
	return value
end

local valid_options = {
	["Return-Path"] = nop,
	["Reply-To"] = nop,
	-- Maybe add these
	-- ["References"] = gc.references_format,
	-- ["In-Reply-To"] = gc.references_format,
}


function Compose:set_compose_option(key, value)
	if valid_options[key] then
		local formated = valid_options[key](value)
		if formated then
			self.options[key] = formated
			return
		end
		vim.notify("Bad value for option", vim.log.levels.ERROR)
		return
	end
	vim.notify("Not a valid compose option", vim.log.levels.ERROR)
end

local function make_default_options(self, from)
	--- XXX get the email from the IA in from
	if not self.options["Return-Path"] then
		self.set_compose_option("Return-Path", from)
	end
	if not self.options["Reply-To"] then
		self.set_compose_option("Reply-To", from)
	end
end

function Compose:set_option_menu()
	local list = u.collect_keys(valid_options)
	vim.ui.select(list,{
		prompt = 'Value to set',
		format_item = function (item)
			return string.format("%s = %s", item, self.options[item] or "")
		end,
	},
	function (item, _)
		if item then
			vim.ui.input(string.format("Value for %s: ", item),
			function (input)
				if input then
					self:set_compose_option(item, input)
				end
			end)
		end
	end)
end

function Compose:unset_option()
	local list = u.collect_keys(self.options)
	vim.ui.select(list,{
		prompt = 'Option to unset',
		format_item = function (item)
			return string.format("%s = %s", item, self.options[item])
		end,
	},
	function (item, _)
		if item then
			self.options[item] = nil
		end
	end)
end

-- this should be move to some util function
-- maybe us virtual lines to split between header and message
-- XXX Adds an empty line to body
function Compose:parse_buffer()
	local box = {}
	local body = {}
	local lines = v.nvim_buf_get_lines(0, 0, -1, true)
	local body_line = vim.api.nvim_buf_get_extmark_by_id(self.handle, self.ns, self.marks, {})[1]
	for i = 1, body_line do
		local start, stop = string.find(lines[i], "^%a+:")
		-- ignore lines that isn't xzy: abc
		if start ~= nil then
			local word = string.sub(lines[i], start, stop - 1)
			word = string.lower(word)
			local content = string.sub(lines[i], stop + 1)
			content = u.trim(content)
			box[word] = content
		end
	end
	if box.subject == nil then
		box.subject = config.values.empty_topyic
	end

	for i = body_line + 1, #lines do
		table.insert(body, lines[i])
	end
	box.body = body
	return box
end

-- Tries to send what is in the current buffer
function Compose:send()
	-- should check for nil
	local buf = self:parse_buffer()
	make_default_options(self, buf.from)
	local message = builder.create_message(buf, self.reply, self.attachments, self.options)
	--- XXX add pre-hooks
	job.send_mail_str(message)
	job.insert_mail_str(message, config.values.sent_folder, config.value.sent_tags)
	--- change the the old tag
	if self.in_reply_to then
		nu.change_tag(self.reply.in_reply_to, "+replied")
	end
	--- XXX add post-hooks
end

function Compose:save_draft()
	local buf = self:parse_buffer()
	local message = builder.create_message(buf, self.reply, self.attachments)
	if ret ~= nil then
		print("Failed to parse draft")
		return ret
	end
	job.insert_mail_str(message, config.values.draftdir, "+draft")
end

local function make_template(message, reply_all)
	local headers = gu.respone_headers(message, reply_all)
	local sub = gp.message_get_subject(message)
	sub = "Subject: " .. u.add_prefix(sub, "Re:")
	table.insert(headers, sub)
	return headers
end

local mark_name = "email-compose"

function Compose:update_attachments()
	if not vim.tbl_isempty(self.attachments) then
		ui.render_attachments(self.attachments, self)
	end
end

function Compose:create(kind, message, reply)
	self.num = self.num + 1
	local template
	local name
	-- local ref = util.get_ref()
	if message then
		template = make_template(message)
		name = string.format("galore-reply: %s", tonumber(self.num))
	else
		template = u.default_template()
		name = string.format("galore-compose: %s", tonumber(self.num))
	end
	Buffer.create({
		name = name,
		ft = "mail",
		kind = kind,
		cursor = "top",
		buftype = "",
		modifiable = true,
		mappings = config.values.key_bindings.compose,
		init = function(buffer)
			buffer.message = message
			buffer.reply = reply
			buffer.attachments = {}
			buffer.options = {}
			-- this is a bit meh
			buffer.ns = vim.api.nvim_create_namespace("email-compose")

			local line_num = #template
			local col_num = 0

			local opts = {
				virt_lines = { { { "Email body", "Comment" } } },
			}
			buffer:clear()

			-- v.nvim_buf_set_lines(buffer.handle, 0, 0, true, template)
			buffer:set_lines(0, 0, true, template)
			if message then
				render.show_message(message, buffer.handle, { reply = true })
			end
			buffer.marks = buffer:set_extmark(buffer.ns, line_num, col_num, opts)
		end,
	}, Compose)
end

return Compose
