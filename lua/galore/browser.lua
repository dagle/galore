local config = require("galore.config")

local Browser = {}

--- Redraw a single line in a browser
-- function Browser.update(browser, line_info, line)
-- 	-- use browser.opts.show_message_description instead
-- 	local formated = config.values.show_message_description(line_info)
-- 	browser:unlock()
-- 	browser:set_lines(line-1, line, true, {formated})
-- 	browser:lock()
-- end

--- Move to the next line in the browser
function Browser.next(browser, line)
	line = math.min(line + 1, #browser.State)
	local line_info = browser.State[line]
	return line_info, line
end

--- Move to the next line in the browser
function Browser.prev(browser, line)
	line = math.max(line - 1, 1)
	local line_info = browser.State[line]
	return line_info, line
end

--- Move to the prev line in the browser
function Browser.select(browser)
	local line = vim.api.nvim_win_get_cursor(0)[1]
	return line, browser.State[line]
end

--- Commit the line to the browser
--- Moving to the next line doesn't really move to the next line
--- it asks for the next line relative to the line in the view
--- This move the line for all windows that has the browser buffer
function Browser.set_line(browser, line)
	local wins = vim.fn.win_findbuf(browser.handle)
	for _, win in ipairs(wins) do
		local location = vim.api.nvim_win_get_cursor(win)
		vim.api.nvim_win_set_cursor(win, {line, location[2]})
	end
end

return Browser
