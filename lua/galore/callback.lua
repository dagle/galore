local job = require("galore.jobs")
local u = require("galore.util")
local util = require("galore.util")
local saved = require("galore.saved")
local threads = require("galore.thread_browser")
local thread_message = require("galore.thread_message_browser")
local conf = require("galore.config")
local mb = require("galore.message_browser")
local thread_view = require("galore.thread_view")
local message_view = require("galore.message_view")
local compose = require("galore.compose")
local gu = require("galore.gmime-util")
local nu = require("galore.notmuch-util")
local tele = require("galore.telescope")

local M = {}

function M.select_search()
	local search = saved:select()[3]
	local ref = saved:ref()
	if conf.values.expand_threads then
		thread_message.create(search, conf.values.threads_open, ref)
	else
		-- threads.create(search, conf.values.threads_open)
	end
	-- mb.create(search, "current")
end

function M.select_thread()
	local thr = threads:select()
	thread_view.create(thr[1], "current")
end

function M.select_message()
	local mes = thread_message:select()
	local ref = thread_message:ref()
	-- local mes = mb:select()
	-- local ref = mb:ref()
	conf.values.tag_unread(mes)
	message_view.create(mes, conf.values.message_open, ref)
end

function M.message_reply()
	local message = message_view:message_ref()
	-- should have a reply-mode
	compose.create("current", message)
end

function M.message_reply_all()
	local message = message_view:message_ref()
	-- should have a reply-mode
	compose.create("current", message, true)
end

function M.save_attach()
	message_view.save_attach()
end

function M.view_attach()
	message_view.view_attachment()
end

-- XXX rethink args to compose?
function M.compose_template() end

-- uses message to create a template
function M.compose_sender() end

function M.change_tag(tag)
	local message = thread_message:select()[1]
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

function M.archive()
	M.change_tag("+archive")
end

function M.delete()
	M.change_tag("+delete")
end

-- a way to get id / filename for piping etc

function M.tree_view() end

function M.compose()
	compose.create("tab")
end

function M.compose_send()
	compose.send_message()
end

function M.compose_add_attachment()
	tele.attach_file({}, compose.add_attachment)
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

function M.close_message()
	message_view.close()
end
-- close_thread
-- close_saved
function M.close_thread()
	thread_message.close()
end

function M.close_saved()
	saved.close()
end

-- function M.reply()
-- 	local mid = message:select()
-- 	compose.create({mid})
-- end
function M.next()
	local mes = thread_message:next()
	local ref = thread_message:ref()
	conf.values.tag_unread(mes)
	message_view.create(mes, conf.values.message_open, ref)
end

function M.prev()
	local mes = thread_message:prev()
	local ref = thread_message:ref()
	conf.values.tag_unread(mes)
	message_view.create(mes, conf.values.message_open, ref)
end

function M.toggle()
	local line = vim.fn.getpos(".")[2]
	local type, uline = thread_message:toggle(line)
	thread_message:redraw()
	if type then
		vim.api.nvim_win_set_cursor(0, { line, 0 })
	else
		vim.api.nvim_win_set_cursor(0, { uline, 0 })
	end
end

function M.call(fun)
	M[fun]()
end

return M
