local message_view = require("galore.message_view")
local compose = require("galore.compose")
local gu = require("galore.gmime.util")
local nu = require("galore.notmuch-util")
local runtime = require("galore.runtime")
local nm = require("galore.notmuch")
local config = require("galore.config")
local br = require("galore.browser")

local M = {}

function M.select_search(saved, browser, mode)
	local search = saved:select()[4]
	browser:create(search, {kind=mode, parent=saved})
end

function M.select_message(browser, mode)
	local vline, line_info = br.select(browser)
	message_view:create(line_info, {kind=mode, parent=browser, vline=vline})
end

function M.get_message(unique, mode)
	local line_info
	runtime.with_db(function (db)
		local message = nm.db_find_message(db, unique)
		line_info = nu.get_message(message)
	end)
	message_view:create(line_info, {kind=mode})
end

function M.yank_browser(browser, select)
	local _, line_info = br.select(browser)
	vim.fn.setreg('', line_info[select])
end

function M.yank_message(mv, select)
	vim.fn.setreg('', mv.line[select])
end

function M.message_reply(mv, opts)
	opts = opts or {}
	local ref
	if vim.tbl_contains(mv.line.tags, "draft") then
		ref = gu.get_ref(mv.message)
	else
		ref = gu.make_ref(mv.message)
		opts.reply = true
	end
	opts.keys = mv.state.keys
	compose:create("replace", mv.message, {ref}, opts)
end

function M.change_tag(browser, tag)
	local vline, line_info = browser:select()
	if tag then
		runtime.with_db_writer(function(db)
			nu.change_tag(db, line_info.id, tag)
			nu.tag_if_nil(db, line_info, config.value.empty_tag)
			nu.update_line(db, browser, line_info, vline)
		end)
	else
		vim.ui.input({ prompt = "Tags change: " }, function(itag)
			if itag then
				runtime.with_db_writer(function(db)
					nu.change_tag(db, line_info.id, tag)
					nu.tag_if_nil(db, line_info, config.value.empty_tag)
					nu.update_line(db, browser, line_info, vline)
				end)
			else
				error("No tag")
			end
		end)
	end
end

return M
