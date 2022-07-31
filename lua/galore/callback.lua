local message_view = require("galore.message_view")
local compose = require("galore.compose")
local gu = require("galore.gmime.util")
local nu = require("galore.notmuch-util")
local runtime = require("galore.runtime")
local config = require("galore.config")
local br = require("galore.browser")

local M = {}

--- Select a saved search and open it in specified browser and mode
--- @param saved any
--- @param browser any
--- @param mode any
function M.select_search(saved, browser, mode)
	local search = saved:select()[4]
	browser:create(search, {kind=mode, parent=saved})
end

--- Open the selected mail in the browser for viewing
--- @param browser any
--- @param mode any
function M.select_message(browser, mode)
	local vline, line_info = br.select(browser)
	message_view:create(line_info, {kind=mode, parent=browser, vline=vline})
end

--- Yank the current line using the selector
--- @param browser any
--- @param select any 
function M.yank_browser(browser, select)
	local _, line_info = br.select(browser)
	vim.fn.setreg('', line_info[select])
end

--- Yank the current message using the selector
--- @param mv any
--- @param select any
function M.yank_message(mv, select)
	vim.fn.setreg('', mv.line[select])
end

--- Create a reply compose from a message view
--- @param mv any
--- @param opts any
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

--- Change the tag for currently selected message and update the browser
--- @param browser any
--- @param tag string +tag to add tag, -tag to remove tag
function M.change_tag(browser, tag)
	local vline, line_info = browser:select()
	if tag then
		runtime.with_db_writer(function(db)
			nu.change_tag(db, line_info.id, tag)
			nu.tag_if_nil(db, line_info, config.value.empty_tag)
			nu.update_line(db, browser, line_info, vline)
		end)
	end
end

--- Ask for a change the tag for currently selected message and update the browser
--- @param browser any
function M.change_tag_ask(browser)
	vim.ui.input({ prompt = "Tags change: " }, function(tag)
		if tag then
			M.change_tag(browser, tag)
		else
			error("No tag")
		end
	end)
end

return M
