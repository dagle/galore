local Buffer = require "galore.lib.buffer"
local o = require "galore.opts"
local async = require "plenary.async"
local browser = require "galore.browser"
local message_view = require "galore.view.message"
local thread_view = require "galore.view.thread"
local message_action = require "galore.message_action"

---@module 'galore.meta.message_browser'

local Tmb = Buffer:new()

Tmb.Commands = {
  change_tag = {
    fun = function(buffer, cmd)
      local tag = require "galore.tags"
      tag.message_change_tags(buffer, cmd.fargs[2])
    end,
  },
  -- Reply = { fun = function (buffer, line)
  --   local mid = buffer.line.id
  --   local kind = get_kind(line.smods)
  --   ma.mid_reply(kind, mid, 'reply', { parent = buffer })
  -- end
  -- },
}

local function tmb_get(self)
  local first = true
  self.highlight = {}
  return browser.get_entries(self, "show-tree", function(thread, n)
    local i = 0
    for _, message in ipairs(thread) do
      table.insert(self.State, message.id)
      if first then
        vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, { message.entry })
        first = false
      else
        vim.api.nvim_buf_set_lines(self.handle, -1, -1, false, { message.entry })
      end
      if message.highlight then
        local idx = i + n - 1
        table.insert(self.highlight, idx)
        vim.api.nvim_buf_add_highlight(self.handle, self.dians, "GaloreHighlight", idx, 0, -1)
      end
      i = i + 1
    end
    -- end
    -- We need to api for folds etc and
    -- we don't want dump all off them like this
    -- but otherwise this works
    -- if #thread > 1 then
    -- 	local threadinfo = {
    -- 		stop = i-1,
    -- 		start = linenr,
    -- 	}
    -- 	table.insert(self.threads, threadinfo)
    -- end
    return i
  end)
end

-- TODO: make private
function Tmb:async_runner()
  self.updating = true
  self.dias = {}
  self.threads = {}
  local func = async.void(function()
    self.runner = tmb_get(self)
    pcall(function()
      self.runner.resume(self.opts.limit)
      self:lock()
      self.updating = false
    end)
  end)
  func()
end

--- Redraw the whole window
function Tmb:refresh()
  if self.runner then
    self.runner.close()
    self.runner = nil
  end
  self:unlock()
  self:clear()
  self:async_runner()
end

-- have an autocmd for refresh?
function Tmb:trigger_refresh()
  -- trigger an refresh in autocmd
end

--- @deprecated use update_message or update_thread
function Tmb:update(line_nr)
  local id = self.State[line_nr]
  browser.update_lines_helper(self, "show-single-tree", "id:" .. id, line_nr)
end

function Tmb:update_message(line_nr)
  local id = self.State[line_nr]
  browser.update_lines_helper(self, "show-single-tree", "id:" .. id, line_nr)
end

function Tmb:update_thread(line_nr)
  --- get the start and stop from the fold
  local id = self.State[line_nr]
  browser.update_lines_helper(self, "show-tree", "id:" .. id, start, stop)
  -- return browser.get_entries(self, "show-tree", function(thread, n)
end


function Tmb:thread()
  local vline, mid = browser.select(self)
  local tid = message_action.get_tid(mid)
  return vline, tid
end

function Tmb:message()
  local vline, mid = browser.select(self)
  return vline, mid
end

function Tmb:thread_next(line)
  --- get to the next toplevel fold
end

function Tmb:thread_prev(line)
  --- get to the prev toplevel fold
end

--- Open the selected mail in the browser for viewing
--- @param mode any
function Tmb:select_message(mode)
  local vline, mid = browser.select(self)
  message_view:create(mid, { kind = mode, parent = self, vline = vline })
end

--- Open the selected thread in the browser for viewing
--- @param mode any
function Tmb:select_thread(mode)
  local vline, mid = browser.select(self)
  local tid = message_action.get_tid(mid)
  thread_view:create(tid, { kind = mode, parent = self, vline = vline, mid = mid })
end

--- Create a browser grouped by threads
--- @param search string a notmuch search string
--- @param opts table
--- @return MessageBrowser
function Tmb:create(search, opts)
  o.tmb_options(opts)
  return Buffer.create({
    name = opts.bufname(search),
    ft = "galore-browser",
    kind = opts.kind,
    cursor = "top",
    parent = opts.parent,
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.search = search
      buffer.opts = opts
      buffer.dians = vim.api.nvim_create_namespace "galore-dia"
      buffer:refresh()
      -- buffer:commands()
      if opts.limit then
        browser.scroll(buffer)
      end
      opts.init(buffer)
    end,
  }, Tmb)
end

return Tmb
