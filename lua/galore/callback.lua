local job = require("galore.jobs")
local u = require('galore.util')
local util = require('galore.util')
local saved = require('galore.saved')
local threads = require('galore.thread_browser')
local thread_message = require('galore.thread_message_browser')
local conf = require('galore.config')
local mb = require('galore.message_browser')
local thread_view = require('galore.thread_view')
local message_view = require('galore.message_view')
local compose = require('galore.compose')
local gu = require('galore.gmime-util')
local gm = require('galore.gmime')

local M = {}

function M.select_search()
	local search = saved:select()[3]
	local ref = saved:ref()
	if conf.values.expand_threads then
		thread_message.create(search, conf.values.threads_open, ref)
	else
		threads.create(search, conf.values.threads_open)
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
	conf.values.tag_unread(mes[1])
	message_view.create(mes[1], conf.values.message_open, ref)
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

-- XXX what should a forward do?
function M.forward()
	local message = message_view:message_ref()
	vim.ui.input({prompt = "Forward to: "}, function (to)
		if to == nil then
			-- alert user that it failed
			return
		end

		local our = gu.get_from(message)
		-- clean smtp headers
		-- clear cc and bcc
		-- clear from
		-- gm.message_add_mailbox(message, 'from', conf.values.name, our)

		local sub = gm.message_get_subject(message)
		sub = u.add_prefix(sub, "Fwd:")
		gm.message_set_subject(message, sub)
		-- set message to, to to
		local message_str = gm.write_message_mem(message)
		job.send_mail(to, our, message_str)
	-- set the to addr
	end)
	-- get our address
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

function M.compose()
	compose.create("tab")
end

function M.compose_send()
	compose.send_message()
end

-- function M.reply()
-- 	local mid = message:select()
-- 	compose.create({mid})
-- end


function M.call(fun)
	M[fun]()
end


return M
