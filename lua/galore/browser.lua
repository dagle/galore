local async_job = require('telescope._')
local LinesPipe = async_job.LinesPipe
local async = require('plenary.async')
local Browser = {}

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
    vim.api.nvim_win_set_cursor(win, { line, location[2] })
  end
end

function Browser.update_lines_helper(self, mode, search, line_nr)
  local bufnr = self.handle
  local args = { 'nm-livesearch', '-d', self.opts.runtime.db_path, mode, search }
  if self.opts.show_message_description then
    args = {
      'nm-livesearch',
      '-e',
      self.opts.show_message_description[1],
      '-r',
      self.opts.show_message_description[2],
      '-d',
      self.opts.runtime.db_path,
      mode,
      search,
    }
  end
  vim.fn.jobstart(args, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data, _)
      vim.api.nvim_err_write(string.format("Couldn't update line for %s and %d", search, line_nr))
    end,
    on_stdout = function(_, data, _)
      local message = vim.fn.json_decode(data)
      if message then
        vim.api.nvim_buf_set_option(bufnr, 'readonly', false)
        vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
        vim.api.nvim_buf_set_lines(bufnr, line_nr - 1, line_nr, false, { message.entry })
        if message.highlight then
          vim.api.nvim_buf_add_highlight(bufnr, self.dians, 'GaloreHighlight', line_nr, 0, -1)
        end
        vim.api.nvim_buf_set_option(bufnr, 'readonly', true)
        vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
      end
    end,
  })
end

function Browser.get_entries(self, mode, buffer_runner)
  local stdout = LinesPipe()
  local writer = nil

  self.State = {}

  local job
  local iter
  local args = { '-d', self.opts.runtime.db_path, mode, self.search }
  if self.opts.show_message_description then
    args = vim.list_extend(
      { '-e', self.opts.show_message_description[1], '-r', self.opts.show_message_description[2] },
      args
    )
  end
  if self.opts.emph then
    local highlight = vim.json.encode(self.opts.emph)
    args = vim.list_extend({ '-h', highlight }, args)
  end

  job = async_job.spawn({
    command = 'nm-livesearch',
    args = args,
    writer = writer,

    stdout = stdout,
  })
  iter = stdout:iter(true)
  return setmetatable({
    close = function()
      if job then
        job:close(true)
      end
      iter = nil -- ?
      self.runner = nil
    end,
    resume = function(numlocal)
      if job and iter then
        local i = 1

        for line in iter do
          local entry = vim.json.decode(line)
          i = i + buffer_runner(entry, i)
          if numlocal and i > numlocal then
            return
          end
        end
        -- idk if I need these first 2
        job:close(true)
        iter = nil
        self.runner = nil
      end
    end,
  }, {
    -- __call = callable,
  })
end

-- Produce more entries when we scroll
function Browser.scroll(self)
  vim.api.nvim_create_autocmd({ 'CursorMoved, WinScrolled' }, {
    buffer = self.handle,
    callback = function()
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local nums = vim.api.nvim_buf_line_count(self.handle)
      local winsize = vim.api.nvim_win_get_height(0)
      local treshold = winsize * 4
      if (nums - line) < treshold then
        -- We should make sure that we are alone!
        if self.runner then
          if not self.updating then
            self.updating = true
            local func = async.void(function()
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

local function find_highlight_helper(highlight, start, stop, pos)
  local mid = math.floor((start + stop) / 2)
  local item = highlight[mid]
  if pos == item then
    return mid
  elseif start == stop then
    if pos < item then
      return start - 1
    else
      return start
    end
  elseif pos > item then
    return find_highlight_helper(highlight, math.min(mid + 1, stop), stop, pos)
  else
    return find_highlight_helper(highlight, start, math.max(mid - 1, start), pos)
  end
end

local function insert_highlight(highlight, pos)
  if pos < highlight[1] then
    table.insert(highlight, pos)
    return
  elseif pos > highlight[#highlight] then
    table.insert(highlight, #highlight, pos)
    return
  end
  local i = find_highlight_helper(highlight, 1, #highlight, pos, false)
  table.insert(highlight, i, pos)
end

local function find_highlight(highlight, pos)
  if pos < highlight[1] or pos > highlight[#highlight] then
    return nil
  end

  local index = find_highlight_helper(highlight, 1, #highlight, pos)
  if highlight[index] ~= pos then
    return nil
  end
  return index
end

local function highlight_move(highlight, win_id, pos, forward)
  local vert_pos = pos[1] - 1
  if not highlight or vim.tbl_isempty(highlight) then
    return
  end

  -- if vert_pos < highlight[1] or vert_pos > highlight[#highlight] then
  --   return nil
  -- end

  local index = find_highlight_helper(highlight, 1, #highlight, vert_pos)

  if not forward and index > 1 then
    vim.api.nvim_win_set_cursor(win_id, { highlight[index - 1] + 1, pos[2] })
  elseif forward and index < #highlight then
    vim.api.nvim_win_set_cursor(win_id, { highlight[index + 1] + 1, pos[2] })
  end
end

function Browser.prev_highlight(browser)
  local win_id = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win_id)

  highlight_move(browser.highlight, win_id, pos, false)
end

function Browser.next_highlight(browser)
  local win_id = vim.api.nvim_get_current_win()
  -- local bufnr = vim.api.nvim_win_get_buf(win_id)
  local pos = vim.api.nvim_win_get_cursor(win_id)

  highlight_move(browser.highlight, win_id, pos, true)
end

return Browser
