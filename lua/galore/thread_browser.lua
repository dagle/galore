local o = require('galore.opts')
local async = require('plenary.async')
local Buffer = require('galore.lib.buffer')
local browser = require('galore.browser')

local Threads = Buffer:new()

local function threads_get(self)
  local first = true
  self.highlight = {}
  return browser.get_entries(self, 'show-thread', function(thread, n)
    if thread then
      table.insert(self.State, thread.id)
      if first then
        vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, { thread.entry })
        first = false
      else
        vim.api.nvim_buf_set_lines(self.handle, -1, -1, false, { thread.entry })
      end
      if thread.highlight then
        table.insert(self.highlight, n)
        vim.api.nvim_buf_add_highlight(self.handle, self.dians, 'GaloreHighlight', n, 0, -1)
      end
      return 1
    end
  end)
end

function Threads:async_runner()
  self.updating = true
  local func = async.void(function()
    self.runner = threads_get(self)
    pcall(function()
      self.runner.resume(self.opts.limit)
      self:lock()
      self.updating = false
    end)
  end)
  func()
end

function Threads:refresh()
  if self.runner then
    self.runner.close()
    self.runner = nil
  end
  self:unlock()
  self:clear()
  self:async_runner()
end

function Threads:update(line_nr)
  local id = self.State[line_nr]
  browser.update_lines_helper(self, 'show-thread', 'thread:' .. id, line_nr)
end

function Threads:commands() end

function Threads:select_thread()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  return line, self.State[line]
end

function Threads:create(search, opts)
  o.threads_options(opts)
  Buffer.create({
    name = opts.bufname(search),
    ft = 'galore-browser',
    kind = opts.kind,
    cursor = 'top',
    parent = opts.parent,
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.opts = opts
      buffer.search = search
      buffer.dians = vim.api.nvim_create_namespace('galore-dia')
      buffer:refresh()
      buffer:commands()
      if opts.limit then
        browser.scroll(buffer)
      end
      opts.init(buffer)
    end,
  }, Threads)
end

return Threads
