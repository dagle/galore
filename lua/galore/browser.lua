local config = require("galore.config")

local Browser = {}

function Browser.update(browser, start)
	local message = browser.State[start]
	local formated = config.values.show_message_description(message)
	browser:unlock()
	browser:set_lines(start-1, start, true, {formated})
	browser:lock()
end

function Browser.next(browser, line)
	line = math.min(line + 1, #browser.State)
	local line_info = browser.State[line]
	return line_info, line
end

function Browser.prev(browser, line)
	line = math.max(line - 1, 1)
	local line_info = browser.State[line]
	return line_info, line
end

function Browser.select(browser)
	local line = vim.api.nvim_win_get_cursor(0)[1]
	return line, browser.State[line]
end

function Browser.set_line(browser, line)
	browser.Line = line
end

return Browser
