local Buffer = require('galore.lib.buffer')
local o = require('galore.opts')
local async = require('plenary.async')
local browser = require('galore.browser')
local message_view = require('galore.view.message')
local thread_view = require('galore.view.thread')
local message_action = require('galore.message_action')

local Mb = Buffer:new()

Mb.Commands = {
  change_tag = { fun = function(buffer, line)
    local cb = require('galore.callback')
    cb.change_tag(buffer, line.fargs[2])
  end},
}

local function mb_get(self)
  local first = true
  self.highlight = {}
  return browser.get_entries(self, 'show-message', function(message, n)
    if message then
      table.insert(self.State, message.id)
      if first then
        vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, { message.entry })
        first = false
      else
        vim.api.nvim_buf_set_lines(self.handle, -1, -1, false, { message.entry })
      end
      if message.highlight then
        table.insert(self.highlight, n)
        vim.api.nvim_buf_add_highlight(self.handle, self.dians, 'GaloreHighlight', n, 0, -1)
      end
      return 1
    end
  end)
end

function Mb:async_runner()
  self.updating = true
  local func = async.void(function()
    self.runner = mb_get(self)
    pcall(function()
      self.runner.resume()
      self:lock()
      self.updating = false
    end)
  end)
  func()
end

function Mb:refresh()
  if self.runner then
    self.runner.close()
    self.runner = nil
  end
  self:unlock()
  self:clear()
  self:async_runner()
end

function Mb:update(line_nr)
  local id = self.State[line_nr]
  browser.update_lines_helper(self, 'show-message', 'id:' .. id, line_nr)
end

function Mb:commands()
  vim.api.nvim_buf_create_user_command(self.handle, 'GaloreChangetag', function(args)
    if args.args then
      local callback = require('galore.callback')
      callback.change_tag(self, args)
    end
  end, {
    nargs = '*',
  })
end

function Mb:thread()
  local _, mid = browser.select(self)
  local tid = message_action.get_tid(mid)
  return nil, tid
end

--- Open the selected mail in the browser for viewing
--- @param mode any
function Mb:select_message(mode)
  local vline, mid = browser.select(self)
  message_view:create(mid, { kind = mode, parent = self, vline = vline })
end

--- Open the selected thread in the browser for viewing
--- @param mode any
function Mb:select_thread(mode)
  local vline, mid = browser.select()
  local tid = message_action(mid)
  thread_view:create(tid, { kind = mode, parent = self, vline = vline, mid = mid})
end

-- create a browser class
function Mb:create(search, opts)
  o.mb_options(opts)
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
  }, Mb)
end

return Mb
