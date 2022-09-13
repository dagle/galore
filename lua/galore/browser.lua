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

--- TODO use opts
function Browser.update_lines_helper(mode, path, bufnr, search, line_nr)
	vim.fn.jobstart({"nm-livesearch", "-d", path, mode, search},
	{
		stdout_buffered = true,
		stderr_buffered = true,
		on_stderr = function (_, data, _)
			vim.api.nvim_err_write(string.format("Couldn't update line for %s and %d", search, line_nr))
		end,
		on_stdout = function (_, data, _)
			local message = vim.fn.json_decode(data)
			vim.api.nvim_buf_set_option(bufnr, "readonly", false)
			vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
			vim.api.nvim_buf_set_lines(bufnr, line_nr-1, line_nr, false, {message.entry})
			vim.api.nvim_buf_set_option(bufnr, "readonly", true)
			vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
		end,
	})
end

function Browser.get_entries(self, mode, buffer_runner)
	local async_job = require "telescope._"
	local LinesPipe = require("telescope._").LinesPipe

	local stdout = LinesPipe()
	local writer = nil

	self.State = {}

	local job
	local iter

	job = async_job.spawn {
		command = "nm-livesearch",
		args = {"-d", self.opts.runtime.db_path, mode, self.search},
		writer = writer,

		stdout = stdout,
	}
	iter = stdout:iter(true)
	return setmetatable({
		close = function()
			if job then
				job:close(true)
			end
			iter = nil -- ?
			self.runner = nil
		end,
		resume = function (numlocal)
			if job and iter then
				local i = 1

				for line in iter do
					local entry = vim.fn.json_decode(line)
					i = i + buffer_runner(entry)
					if numlocal and  i > numlocal then
						return
					end
				end
				-- idk if I need these first 2
				job:close(true)
				iter = nil
				self.runner = nil
				end
			end
		}, {
			-- __call = callable,
		})
end

-- Produce more entries when we scroll
function Browser.scroll(self)
	vim.api.nvim_create_autocmd({"CursorMoved, WinScrolled"}, {
		buffer = self.handle,
		callback = function ()
			local line = vim.api.nvim_win_get_cursor(0)[1]
			local nums = vim.api.nvim_buf_line_count(self.handle)
			local winsize = vim.api.nvim_win_get_height(0)
			local treshold = winsize*4
			if (nums - line) < treshold then
				-- We should make sure that we are alone!
				if self.runner then
					if not self.updating then
						self.updating = true
						local func = async.void(function ()
							self:unlock()
							self.runner.resume(math.max(treshold, self.opts.limit))
							self:lock()
							self.updating = false
						end)
						func()
					end
				end
			end
		end,
	})
end

return Browser
