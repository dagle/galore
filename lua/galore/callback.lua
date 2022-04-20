local message_view = require("galore.message_view")
local compose = require("galore.compose")
local gu = require("galore.gmime.util")
local nu = require("galore.notmuch-util")
local runtime = require("galore.runtime")
local nm = require("galore.notmuch")

local M = {}

function M.select_search(saved, browser, mode)
	local search = saved:select()[4]
	browser:create(search, mode, saved)
end

function M.select_message(browser, mode)
	local vline, line_info = browser:select()
	message_view:create(line_info, mode, browser, vline)
end

function M.get_message(unique, mode)
	local line_info
	runtime.with_db(function (db)
		local message = nm.db_find_message(db, unique)
		line_info = nu.get_message(message)
	end)
	message_view:create(line_info, mode, nil, nil)
end

function M.yank_browser(browser, select)
	local _, line_info = browser:select()
	vim.fn.setreg('', line_info[select])
end

function M.yank_message(mv, select)
	vim.fn.setreg('', mv.line[select])
end

function M.message_reply(mv)
	local ref
	if vim.tbl_contains(mv.line.tags, "draft") then
		ref = gu.get_ref(mv.message)
	else
		ref = gu.make_ref(mv.message)
	end
	compose:create("replace", mv.message, ref)
end

--- XXX todo!
function M.message_reply_all(mv)
	local ref = gu.make_ref(mv.message)
	compose:create("replace", mv.message, ref)
end

function M.add_search(browser)
	nu.add_search(browser.search)
end

--- move this
-- local function update_line(browser, line_info, vline)
-- 	nu.update_line(browser, line_info, vline)
-- end

function M.change_tag(browser, tag)
	local vline, line_info = browser:select()
	if tag then
		nu.change_tag(line_info.id, tag)
		nu.tag_if_nil(line_info, config.value.empty_tag)
		nu.update_line(browser, line_info, vline)
	else
		vim.ui.input({ prompt = "Tags change: " }, function(itag)
			if itag then
				nu.change_tag(line_info.id, itag)
				nu.tag_if_nil(line_info, config.value.empty_tag)
				nu.update_line(browser, line_info, vline)
			else
				error("No tag")
			end
		end)
	end
end

-- XXX what should a forward do?
--- https://datatracker.ietf.org/doc/html/rfc2076#section-3.14
function M.forward()
	local message = message_view:message_ref()
	vim.ui.input({ prompt = "Forward to: " }, function(to)
		if to == nil then
			-- local new = gu.forward(message, to)
			-- job.send_mail(to, our, message_str)
			return
		end
	end)
	runtime.with_db(function (db)
		nu.tag_change(db, message, "+passed")
	end)
end

function M.toggle(tmb)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local expand, uline, stop, thread = tmb:toggle(cursor[1])
	tmb:redraw(expand, uline, stop, thread)
	-- tmb:threads_to_buffer()
	if expand then
		vim.api.nvim_win_set_cursor(0, cursor)
	else
		vim.api.nvim_win_set_cursor(0, { uline, cursor[2] })
	end
end

return M
