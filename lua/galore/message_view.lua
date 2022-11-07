local r = require('galore.render')
local u = require('galore.util')
local Buffer = require('galore.lib.buffer')
local views = require('galore.views')
local ui = require('galore.ui')
local nu = require('galore.notmuch-util')
local nm = require('notmuch')
local runtime = require('galore.runtime')
local browser = require('galore.browser')
local o = require('galore.opts')
local gu = require('galore.gmime-util')

local Message = Buffer:new()

--- add opts
function Message:select_attachment(cb)
  local files = {}
  for _, v in ipairs(self.state.attachments) do
    table.insert(files, v.filename)
  end
  vim.ui.select(files, {
    prompt = 'Select attachment: ',
  }, function(item, idx)
    if item then
      cb(self.state.attachments[idx])
    else
      error('No file selected')
    end
  end)
end

function Message:update()
  self:unlock()
  self:clear()

  local message = gu.parse_message(self.line.filenames[self.index])
  -- au.process_au(message, line)
  if message then
    vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
    self.message = message
    local buffer = {}

    r.show_headers(message, self.handle, { ns = self.ns }, self.line)
    local offset = vim.fn.line('$') - 1
    self.state = r.render_message(r.default_render, message, buffer, {
      offset = offset,
      keys = self.line.keys,
    })
    u.purge_empty(buffer)
    self:set_lines(-1, -1, true, buffer)
    local ns_line = vim.fn.line('$') - 1
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

local function mark_read(self, pb, line, vline)
  runtime.with_db_writer(function(db)
    self.opts.tag_unread(db, line.id)
    nu.tag_if_nil(db, line.id, self.opts.empty_tag)
    nu.update_line(db, line)
  end)
  if vline and pb then
    pb:update(vline)
  end
end

function Message:next()
  if self.vline and self.parent then
    local mid, vline = browser.next(self.parent, self.vline)
    Message:create(mid, { kind = 'replace', parent = self.parent, vline = vline })
  end
end
--
function Message:prev()
  if self.vline and self.parent then
    local mid, vline = browser.prev(self.parent, self.vline)
    Message:create(mid, { kind = 'replace', parent = self.parent, vline = vline })
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

function Message:commands()
  vim.api.nvim_buf_create_user_command(self.handle, 'GaloreSaveAttachment', function(args)
    if args.fargs then
      local save_path = '.'
      if #args.fargs > 2 then
        save_path = args.fargs[2]
      end
      views.save_attachment(self.state.attachments, args.fargs[1], save_path)
    end
  end, {
    nargs = '*',
    complete = function()
      local files = {}
      for _, v in ipairs(self.state.attachments) do
        table.insert(files, v.filename)
      end
      return files
    end,
  })
end

function Message:thread_view()
  local tw = require('galore.thread_view')
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
    ft = 'mail',
    kind = opts.kind,
    parent = opts.parent,
    cursor = 'top',
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.line = line
      buffer.opts = opts
      buffer.index = opts.index or 1
      buffer.vline = opts.vline
      buffer.ns = vim.api.nvim_create_namespace('galore-message-view')
      buffer.dians = vim.api.nvim_create_namespace('galore-dia')
      mark_read(buffer, opts.parent, line, opts.vline)
      buffer:update()
      buffer:commands()
      opts.init(buffer)
    end,
  }, Message)
end

function Message.open_attach() end

return Message
