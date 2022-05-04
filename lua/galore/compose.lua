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
local gc = require("galore.gmime.content")
local nu = require("galore.notmuch-util")

local Compose = Buffer:new()

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

local headers = {
	["Return-Path"] = nop,
	["Reply-To"] = nop,
	["References"] = gc.references_format,
	["In-Reply-To"] = gc.references_format,
}

function Compose:set_compose_option(key, value)
	if headers[key] then
		local formated = headers[key](value)
		if formated then
			self.opts[key] = formated
			return
		end
		vim.notify("Bad value for option", vim.log.levels.ERROR)
		return
	end
	vim.notify("Not a valid compose option", vim.log.levels.ERROR)
end

local function make_options(self, opts)
	for key, value in pairs(opts) do
		self:set_compose_option(key, value)
	end
end

function Compose:set_option_menu()
	local list = u.collect_keys(headers)
	vim.ui.select(list,{
		prompt = 'Value to set',
		format_item = function (item)
			return string.format("%s = %s", item, self.opts[item] or "")
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
	local list = u.collect_keys(self.opts)
	vim.ui.select(list,{
		prompt = 'Option to unset',
		format_item = function (item)
			return string.format("%s = %s", item, self.opts[item])
		end,
	},
	function (item, _)
		if item then
			self.opts[item] = nil
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

local function get_sent_folder(sent_folder, from)
	if type(sent_folder) == "string" then
		return sent_folder
	elseif type(sent_folder) == "function" then
		return sent_folder(from)
	end
	return "sent"
end

-- Tries to send what is in the current buffer
function Compose:send()
	-- should check for nil
	local buf = self:parse_buffer()
	-- dunno about this
	-- make_default_options(self, buf.from)
	local message = builder.create_message(buf, self.reply, self.attachments, self.opts)
	--- XXX add pre-hooks
	job.send_mail(message)
	-- we should try to figure out the sent folder from the message
	-- local folder = get_sent_folder(config.values.sent_folder, buf.from)
	-- job.insert_mail(message, folder, config.values.sent_tags)
	--- change the the old tag
	if self.in_reply_to then
		nu.change_tag(self.reply.in_reply_to, "+replied")
	end
	--- XXX add post-hooks
	--- maybe move this to hooks?
	self:set_option("modified", false)
end

local ffi = require("ffi")
local gs = require("galore.gmime.stream")
local go = require("galore.gmime.object")
local runtime = require("galore.runtime")

function Compose:preview(kind)
	local buf = self:parse_buffer()
	-- make_default_options(self, buf.from)
	local message = builder.create_message(buf, self.attachments, self.opts, builder.textbuilder)
	local object = ffi.cast("GMimeObject *", message)
	local mem = gs.stream_mem_new()
	go.object_write_to_stream(object, runtime.format_opts, mem)
	gs.stream_flush(mem)
	local str = gu.mem_to_string(mem)
	local tbl = vim.split(str, "\n")
	Buffer.create({
		name = "Galore-preview",
		ft = "mail",
		kind = kind or "floating",
		cursor = "top",
		init = function(buffer)
			buffer:set_lines(0, 0, true, tbl)
		end,
	})
end

function Compose:save_draft()
	local buf = self:parse_buffer()
	local message = builder.create_message(buf, self.attachments, self.opts, builder.textbuilder)
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

local mark_name = "email-compose"

function Compose:update_attachments()
	if not vim.tbl_isempty(self.attachments) then
		ui.render_attachments(self.attachments, self)
	end
end

function Compose:delete_tmp()
	-- vim.fn.delete()
end

-- change message to file
function Compose:create(kind, message, opts)
	local template
	if message then
		template = make_template(message, opts.response_mode)
	else
		template = u.default_template()
	end
	-- vim.fn.writefile()
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
			buffer.attachments = {}
			buffer.opts = {}
			make_options(buffer, opts)
			-- this is a bit meh
			buffer.ns = vim.api.nvim_create_namespace("email-compose")

			local line_num = #template
			local col_num = 0

			local virt_lines = {
				virt_lines = { { { "Email body", "Comment" } } },
			}
			buffer:clear()

			-- v.nvim_buf_set_lines(buffer.handle, 0, 0, true, template)
			buffer:set_lines(0, 0, true, template)
			if message then
				render.show_message(message, buffer.handle, { reply = true })
			end
			buffer.marks = buffer:set_extmark(buffer.ns, line_num, col_num, virt_lines)
			vim.api.nvim_create_autocmd("BufWritePost", {
				callback = function ()
					buffer:save_draft()
					buffer:delete_tmp()
				end,
				buffer = buffer.handle})
			buffer:set_option("modified", false)
		end,
	}, Compose)
end

return Compose
