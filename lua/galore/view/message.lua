local r = require "galore.render"
local u = require "galore.util"
local Buffer = require "galore.lib.buffer"
local views = require "galore.view"
local ui = require "galore.ui"
local nu = require "galore.notmuch-util"
local nm = require "notmuch"
local runtime = require "galore.runtime"
local browser = require "galore.browser"
local o = require "galore.opts"
local gu = require "galore.gmime-util"
local ma = require "galore.message_action"
local tag = require "galore.tags"

--- @module 'galore.meta.view'

--- @class Message : View
local Message = Buffer:new()

Message.Commands = {
  reply = {
    fun = function(buffer, line)
      local mid = buffer.line.id
      local kind = u.get_kind(line.smods)
      ma.mid_reply(kind, mid, "reply", { parent = buffer })
    end,
  },
  reply_all = {
    fun = function(buffer, line)
      local mid = buffer.line.id
      local kind = u.get_kind(line.smods)
      ma.mid_reply(kind, mid, "reply_all", { parent = buffer })
    end,
  },
  save = {
    fun = function(buffer, line)
      --- if browser is set we should do another function
      if line.smods.browse then
        views.select_attachment(buffer.state.attachments, function(attach)
          views.save_attachment(attach, ".", line.smods.confirm)
        end)
        return
      end
      local attachment = line.fargs[2]
      if not attachment then
        error "No attachment selected"
      end
      local save_path = line.fargs[3] or "."
      views.save_attachment(buffer.state.attachments, attachment, save_path, line.smods.confirm)
    end,
    cmp = {
      function(buffer)
        local files = {}
        for _, v in ipairs(buffer.state.attachments) do
          table.insert(files, v.filename)
        end
        return files
      end,
    },
  },
  web_view = {
    fun = function(buffer, line)
      local tele = require "galore.telescope.parts"
      tele.parts_pipe(buffer.message, { "browser-pipe" })
    end,
  },
}

--- returns a list of attachments
function Message:get_attachments(cb)
  local files = {}
  for _, v in ipairs(self.state.attachments) do
    table.insert(files, v.filename)
  end
  vim.ui.select(files, {
    prompt = "Select attachment: ",
  }, function(item, idx)
    if item then
      cb(self.state.attachments[idx])
      -- function M.save_attachment_index(attachments, index, save_path, overwrite)
    else
      error "No file selected"
    end
  end)
end

function Message:update()
  self:unlock()
  self:clear()

  local message = gu.parse_message(self.line.filenames[self.index])

  if message then
    vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
    self.message = message
    local buffer = {}

    r.show_headers(message, self.handle, { ns = self.ns }, self.line)
    local offset = vim.fn.line "$" - 1
    self.state = r.render_message(r.default_render, message, buffer, {
      offset = offset,
      keys = self.line.keys,
    })
    u.purge_empty(buffer)
    self:set_lines(-1, -1, true, { "" })
    self:set_lines(-1, -1, true, buffer)
    local ns_line = vim.fn.line "$" - 1
    if not vim.tbl_isempty(self.state.attachments) then
      ui.render_attachments(self.state.attachments, ns_line, self.handle, self.ns)
    end
    vim.schedule(function()
      for i, cb in ipairs(self.state.callbacks) do
        cb(self.handle, self.ns)
        self.state.callbacks[i] = nil
      end
    end)
  end
  self:lock()
end

function Message:redraw()
  self:focus()
  self:update()
end

---@param view Message
---@param pb Browser Parrent buffer
---@param line table
---@param vline integer line in the parent we want to rerun
local function mark_read(view, pb, line, vline)
  if view.opts.tag_unread then
    runtime.with_db_writer(function(db)
      --- TODO: tag_unread should return a bool if we updated a tag
      --- or not, so we don't run updates if not needed
      view.opts.tag_unread(db, line.id)
      tag.tag_if_nil(db, line.id, view.opts.empty_tag)
      nu.update_line(db, line)
    end)
    if vline and pb then
      pb:update(vline)
    end
  end
end

function Message:next()
  if self.vline and self.parent then
    local mid, vline = browser.next(self.parent, self.vline)
    Message:create(mid, { kind = "default", parent = self.parent, vline = vline })
  end
end

function Message:prev()
  if self.vline and self.parent then
    local mid, vline = browser.prev(self.parent, self.vline)
    Message:create(mid, { kind = "default", parent = self.parent, vline = vline })
  end
end

function Message:version_next()
  self.index = math.max(#self.line.filenames, self.index + 1)
  self:redraw()
end

function Message:version_prev()
  self.index = math.min(1, self.index - 1)
  self:redraw()
end

function Message:thread_view()
  local tw = require "galore.thread_view"
  local opts = o.bufcopy(self.opts)
  opts.index = self.line.index
  tw:create(self.line.tid, opts)
end

function Message:create(mid, opts)
  o.view_options(opts)
  local line
  runtime.with_db(function(db)
    local message = nm.db_find_message(db, mid)
    line = nu.get_message(message)
    nu.line_populate(db, line)
  end)
  Buffer.create({
    name = opts.bufname(line.filenames[1]),
    ft = "mail",
    kind = opts.kind,
    parent = opts.parent,
    cursor = "top",
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.line = line
      buffer.opts = opts
      buffer.index = opts.index or 1
      buffer.vline = opts.vline
      buffer.ns = vim.api.nvim_create_namespace "galore-message-view"
      buffer.dians = vim.api.nvim_create_namespace "galore-dia"
      mark_read(buffer, opts.parent, line, opts.vline)
      buffer:update()
      opts.init(buffer)
    end,
  }, Message)
end

function Message.open_attach() end

return Message
