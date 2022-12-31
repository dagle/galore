local u = require('galore.util')
local gu = require('galore.gmime-util')
local ui = require('galore.ui')
local Buffer = require('galore.lib.buffer')
local job = require('galore.jobs')
local builder = require('galore.builder')
local nu = require('galore.notmuch-util')
local runtime = require('galore.runtime')
local Path = require('plenary.path')
local debug = require('galore.debug')
local o = require('galore.opts')
local log = require('galore.log')
-- local hd = require("galore.header-diagnostics")

local Compose = Buffer:new()

function Compose:add_attachment_path(file_path)
  local path = Path:new(file_path)
  if path:exists() and not path:is_file() then
    local filename = path:normalize()
    local mime_type = job.get_type(file_path)
    table.insert(self.attachments, { filename = filename, path = file_path, mime_type = mime_type })
  else
    log.log('Failed to add file', vim.log.levels.ERROR)
  end
end

function Compose:remove_attachment()
  vim.ui.select(self.attachments, { prompt = 'delete attachment' }, function(_, idx)
    if idx then
      table.remove(self.attachments, idx)
    end
  end)
  self:update_attachments()
end

function Compose:set_header_option(key, value)
  self.extra_headers[key] = value
end

function Compose:unset_option()
  local list = vim.tbl_keys(self.extra_headers)
  vim.ui.select(list, {
    prompt = 'Option to unset',
    format_item = function(item)
      return string.format('%s = %s', item, self.extra_headers[item])
    end,
  }, function(item, _)
    if item then
      self.extra_headers[item] = nil
    end
  end)
end

local function empty(str)
  return u.trim(str) == ''
end

--- TODO Test multiline!
local function get_headers(self)
  local headers = {}
  local body_line = vim.api.nvim_buf_get_extmark_by_id(self.handle, self.compose, self.marks, {})[1]
  local lines = vim.api.nvim_buf_get_lines(self.handle, 0, body_line, true)
  local last_key
  for i, line in ipairs(lines) do
    if empty(line) then
      goto continue
    end
    local start, _, key, value = string.find(line, '^%s*(.-)%s*:(.+)')
    if start ~= nil and key ~= '' and value ~= '' then
      key = string.lower(key)
      last_key = key
      value = vim.fn.trim(value)
      headers[key] = value
    else
      if not last_key then
        -- this should be a log function
        local str = "Bad formated headers, trying to add to value header above that doesn't exist"
        log.log(str, vim.log.levels.ERROR)
        error(str)
      end
      -- local value, prev = unpack(headers[last_key])
      local key = headers[last_key]
      local extra = vim.fn.trim(line)
      -- headers[key] = {value .. " " .. extra, prev}
      headers[key] = value .. ' ' .. extra
    end
    ::continue::
  end
  return headers, body_line
end

function Compose:parse_buffer()
  local buf = {}
  local headers, body_line = get_headers(self)
  -- local lines = vim.api.nvim_buf_line_count(self.handle)
  local body = vim.api.nvim_buf_get_lines(self.handle, body_line + 1, -1, false)
  if headers.subject == nil then
    headers.subject = self.opts.empty_topic
  end

  -- for i = body_line + 1, lines do
  -- 	table.insert(body, lines[i])
  -- end
  buf.body = body
  buf.headers = headers
  return buf
end

-- TODO add opts
function Compose:preview(kind)
  kind = kind or 'floating'
  local buf = self:parse_buffer()

  local message =
    builder.create_message(buf, self.opts, self.attachments, self.header_opts, builder.textbuilder)
  debug.view_raw_message(message, kind)
  self:set_option('modified', false)
end

-- Tries to send what is in the current buffer
function Compose:send()
  -- local opts = {}
  local buf = self:parse_buffer()
  --- should be do encryt here or not?

  --- from here we want to be async
  local message = builder.create_message(
    buf,
    self.opts,
    self.attachments,
    self.extra_headers,
    builder.textbuilder
  )
  if not message then
    log.log("Couldn't create message for sending", vim.log.levels.ERROR)
    return
  end
  if self.opts.pre_sent_hooks then
    self.opts.pre_sent_hooks(message)
  end

  job.send_mail(message, function()
    log.log('Email sent', vim.log.levels.INFO)
    local reply = message:get_header('References')
    if reply then
      local mid = gu.unbracket(reply)
      runtime.with_db_writer(function(db)
        nu.change_tag(db, mid, '+replied')
      end)
    end
    --- add an option for this or move it to post_ehooks?
    job.insert_mail(message, self.opts.sent_dir, '+sent')
    if self.opts.post_sent_hooks then
      self.opts.post_sent_hooks(message)
    end
  end)
  self:set_option('modified', false)
end

function Compose:save_draft(build_opts)
  build_opts = build_opts or {}
  local buf = self:parse_buffer()
  if self.opts.draft_encrypt and self.opts.gpg_id then
    build_opts.encrypt = true
    build_opts.recipients = self.opts.gpg_id
  end
  local message = builder.create_message(
    buf,
    build_opts,
    self.attachments,
    self.extra_headers,
    builder.textbuilder
  )
  if not message then
    log.log("Couldn't create message for sending", vim.log.levels.ERROR)
    return
  end
  --- TODO from here we want to be async
  job.insert_mail(message, self.opts.draft_dir, self.opts.draft_tag)
end

function Compose:update_attachments()
  vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
  local line = vim.fn.line('$') - 1
  ui.render_attachments(self.attachments, line, self.handle, self.ns)
end

function Compose:delete_tmp()
  -- vim.fn.delete()
end

local function addfiles(self, files)
  self.attachments = {}
  if not files then
    return
  end
  if type(files) == 'string' then
    self:add_attachment_path(files)
    return
  else
    self.attachments = files
  end
end

local function make_seperator(buffer, lines)
  local line_num = lines
  local col_num = 0

  local opts = {
    virt_lines = {
      { { 'Emailbody', 'GaloreSeperator' } },
    },
  }
  buffer.marks = buffer:set_extmark(buffer.compose, line_num, col_num, opts)
end

function Compose:commands()
  vim.api.nvim_buf_create_user_command(self.handle, 'GaloreAddAttachment', function(args)
    if args.fargs then
      for _, value in ipairs(args.fargs) do
        self:add_attachment(value)
      end
      self:update_attachments()
    end
  end, {
    nargs = '*',
    complete = 'file',
  })
  vim.api.nvim_buf_create_user_command(self.handle, 'GalorePreview', function()
    self:preview()
  end, {
    nargs = 0,
  })
  vim.api.nvim_buf_create_user_command(self.handle, 'GaloreSend', function()
    self:send()
  end, {
    nargs = 0,
  })
end

local function consume_headers(buffer)
  local lines = {}
  local extra_headers = {}
  local lookback = {}
  for _, v in ipairs(buffer.opts.compose_headers) do
    lookback[v[1]] = v[2]
  end

  for _, v in ipairs(buffer.opts.compose_headers) do
    if v[2] and not buffer.headers[v[1]] then
      local header = string.format('%s: ', v[1])
      table.insert(lines, header)
    elseif buffer.headers[v[1]] then
      local header = string.format('%s: %s', v[1], buffer.headers[v[1]])
      local multiline = vim.fn.split(header, '\n')
      vim.list_extend(lines, multiline)
    end
  end

  for k, v in pairs(buffer.headers) do
    if lookback[k] == nil then
      extra_headers[k] = v
    end
  end
  buffer.extra_headers = extra_headers
  buffer:set_lines(0, 0, true, lines)
end

local function render_body(buffer)
  if buffer.body then
    buffer:set_lines(-1, -1, true, buffer.body)
  end
end

function Compose:update()
  self:clear()
  consume_headers(self)
  local after = vim.fn.line('$') - 1
  render_body(self)

  make_seperator(self, after)
end

local function checkheaders(self)
  vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function()
      local headers = get_headers(self)
      hd.checkheaders(self.dians, self.handle, headers)
    end,
    buffer = self.handle,
  })
end

-- change message to file
function Compose:create(kind, opts)
  o.compose_options(opts)
  Buffer.create({
    name = opts.bufname(),
    ft = 'mail',
    kind = kind,
    cursor = 'top',
    parent = opts.parent,
    buftype = '', -- fix this
    modifiable = true,
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.opts = opts
      buffer.headers = opts.headers
      buffer.body = opts.Body
      addfiles(buffer, opts.Attach)
      buffer.ns = vim.api.nvim_create_namespace('galore-attachments')
      buffer.compose = vim.api.nvim_create_namespace('galore-compose')
      buffer.dians = vim.api.nvim_create_namespace('galore-dia')
      buffer:update()
      -- checkheaders(buffer)

      buffer:set_option('modified', false)

      buffer:update_attachments()
      opts.init(buffer)
      buffer:commands()
    end,
  }, Compose)
end

return Compose
