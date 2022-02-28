local job = require("galore.jobs")
local u = require("galore.util")
local util = require("galore.util")
-- local saved = require("galore.saved")
-- local threads = require("galore.thread_browser")
local thread_message = require("galore.thread_message_browser")
local config = require("galore.config")
local mb = require("galore.message_browser")
local thread_view = require("galore.thread_view")
local message_view = require("galore.message_view")
local compose = require("galore.compose")
local gu = require("galore.gmime-util")
local nu = require("galore.notmuch-util")
local tele = require("galore.telescope")
local nm = require("galore.notmuch")

local M = {}

function M.select_search(saved, mode)
	local search = saved:select()[3]
	if config.values.thread_browser then
		thread_message.create(search, mode, saved)
	else
	mb.create(search, mode)
	end
end

function M.select_message(tmb, mode)
	local mes = tmb:select()
	config.values.tag_unread(mes)
	local file = nm.message_get_filename(mes)
	message_view.create(file, mode, tmb)
end

function M.message_reply(message_view)
	local ref = gu.make_ref(message_view.message)
	compose.create("replace", message_view.message, ref)
end

function M.message_reply_all(message_view)
	local ref = gu.make_ref(message_view.message)
	compose.create("replace", message_view.message, ref)
end

function M.change_tag(tmb, tag)
	local message = tmb:select()[1]
	if tag then
		nu.tag_change(tag)
	else
		vim.ui.input({ prompt = "Tags change: " }, function(itag)
			if itag then
				nu.change_tag(message, itag)
			else
				error("No tag")
			end
		end)
	end
end

-- XXX what should a forward do?
function M.forward()
	local message = message_view:message_ref()
	vim.ui.input({ prompt = "Forward to: " }, function(to)
		if to == nil then
			-- local new = gu.forward(message, to)
			-- job.send_mail(to, our, message_str)
			return
		end
	end)
end

function M.toggle(tmb)
	local line = vim.fn.getpos(".")[2]
	local expand, uline, stop, thread = tmb:toggle(line)
	tmb:redraw(expand, uline, stop, thread)
	if expand then
		vim.api.nvim_win_set_cursor(0, { line, 0 })
	else
		vim.api.nvim_win_set_cursor(0, { uline, 0 })
	end
end

function M.call(fun)
	M[fun]()
end

return M
