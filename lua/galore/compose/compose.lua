local u = require('galore.util')
local ui = require('galore.ui')
local Buffer = require('galore.lib.buffer')
local job = require('galore.jobs')
local builder = require('galore.compose.builder')
local nu = require('galore.notmuch-util')
local runtime = require('galore.runtime')
local Path = require('plenary.path')
local debug = require('galore.debug')
local o = require('galore.opts')
local log = require('galore.log')

local Compose = Buffer:new()

Compose.Commands = {
  add_attachment = { fun = function (buffer, line)
    if line.smods.browse then
      tele.add_attachment(buffer)
      return
    end
    buffer:add_attachment_path(line.fargs[2])
  end, },
  remove_attachment = { fun = function (buffer, line)
    -- needs to be able to use browse
    buffer:add_attachment_path(line.fargs[2])
  end, },
  preview = { fun = function (buffer, _)
    buffer:preview()
  end },
  send = { fun = function (buffer, _)
    buffer:send()
  end },
  save_draft = { fun = function (buffer, _)
    buffer:save_draft()
  end },
  show_headers = { fun = function(buffer, _)
    vim.print(buffer.extra_headers)
  end },
  push_header = { fun = function(buffer, _)
    buffer:push_heder()
  end},
}

function Compose:add_attachment_path(file_path)
  local path = Path:new(file_path)
  if path:exists() and path:is_file() then
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

function Compose:unset_header()
  local list = vim.tbl_keys(self.extra_headers)
  vim.ui.select(list, {
    prompt = 'header',
    format_item = function(item)
      return string.format('%s = %s', item, self.extra_headers[item])
    end,
  }, function(item, _)
    if item then
      self.extra_headers[item] = nil
    end
  end)
end

function Compose:push_header()
  local list = vim.tbl_keys(self.extra_headers)
  vim.ui.select(list, {
    prompt = 'head',
    format_item = function(item)
      return string.format('%s = %s', item, self.extra_headers[item])
    end,
  }, function(item, _)
    if item then
      local value = string.format('%s = %s', item, self.extra_headers[item])
      self.extra_headers[item] = nil
      local body_line = vim.api.nvim_buf_get_extmark_by_id(self.handle, self.compose, self.marks, {})[1]
      self:set_lines(body_line, body_line, false, {value})
    end
  end)
end

local function empty(str)
  return u.trim(str) == ''
end

-- TODO: Test multiline!

local function get_headers(self)
  local headers = {}
  local body_line = vim.api.nvim_buf_get_extmark_by_id(self.handle, self.compose, self.marks, {})[1]
  local lines = vim.api.nvim_buf_get_lines(self.handle, 0, body_line, true)
  local last_key
  for _, line in ipairs(lines) do
    if empty(line) then
      last_key = nil
      goto continue
    end
    local start, _, key, value = string.find(line, '^%s*(.-)%s*:(.+)')
    if start ~= nil and key ~= '' and value ~= '' then
      key = string.lower(key)
      last_key = key
      value = vim.fn.trim(value)
      -- maybe headers[key] += value?
      headers[key] = value
    else
      if not last_key then
        -- this should be a log function
        local str = "Bad formated headers, trying to add to value header above that doesn't exist"
        log.log(str, vim.log.levels.ERROR)
        error(str)
      end
      local prev = headers[last_key]
      local extra = vim.fn.trim(line)
      headers[last_key] = prev .. ' ' .. extra
    end
    ::continue::
  end
  return headers, body_line
end

--- should return a msg
function Compose:parse_buffer()
  local headers, body_line = get_headers(self)
  local body = vim.api.nvim_buf_get_lines(self.handle, body_line + 1, -1, false)

  local msg = templ.buffer(headers, self.extra_headers)

  if msg.headers.Subject == nil then
    headers.Subject = self.opts.empty_subject
  end

  msg.body = body
  msg.attachments = self.attachments
  return msg
end

-- TODO add opts
function Compose:preview(kind)
  kind = kind or 'floating'
  local msg = self:parse_buffer()

  local message =
    builder.create_message(msg, self.opts)
  debug.view_raw_message(message, kind)
  self:set_option('modified', false)
end

-- Tries to send what is in the current buffer
function Compose:send()
  local msg = self:parse_buffer()
  --- should be do encryt here or not?

  --- from here we want to be async
  local message = builder.create_message(msg, self.opts)
  if not message then
    log.log("Couldn't create message for sending", vim.log.levels.ERROR)
    return
  end
  if self.opts.pre_sent_hooks then
    self.opts.pre_sent_hooks(message)
  end

  job.send_mail(message, function()
    log.log('Email sent', vim.log.levels.INFO)
    if msg.headers["In-reply-To"] then
      local mid = msg.headers["In-reply-To"]
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
  local msg = self:parse_buffer()

  if self.opts.draft_encrypt and self.opts.pgp_id then
    build_opts.encrypt = true
    build_opts.sign = false -- don't sign a draft
    build_opts.recipients = self.opts.pgp_id
  end
  local message = builder.create_message(msg, build_opts)

  if not message then
    log.log("Couldn't create message for sending", vim.log.levels.ERROR)
    return
  end
  --- TODO from here we want to be async
  job.insert_mail(message, self.opts.draft_dir, self.opts.draft_tag)
  self:set_option('modified', false)
end

function Compose:update_attachments()
  vim.api.nvim_buf_clear_namespace(self.handle, self.ns, 0, -1)
  local line = vim.fn.line('$') - 1
  ui.render_attachments(self.attachments, line, self.handle, self.ns)
end

function Compose:delete_tmp()
  -- vim.fn.delete()
end

function Compose:addfiles(files)
  self.attachments = {}
  if not files then
    return
  end
  if type(files) == 'string' then
    self:add_attachment_path(files)
  elseif type(files) == "table" then
    self.attachments = files
  end
end

function Compose:make_seperator(line_num)
  local col_num = 0

  local opts = {
    virt_lines = {
      { { 'Emailbody', 'GaloreSeperator' } },
    },
  }
  self.marks = self:set_extmark(self.compose, line_num, col_num, opts)
end

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
-- this function is overly messy because we want to print the headers in a
-- defined order.
function Compose:consume_headers(msg)
  local headers = msg:dump_headers()
  local rendered = {}
  local extra_headers = {}
  -- local headers = msg.headers or {}

  for _, v in ipairs(headers) do
    extra_headers[v[1]] = v[2]
  end

  for _, v in ipairs(self.opts.compose_headers) do
    -- We want to show this header but the value is empty
    if v[2] and not headers[v[1]] then
      local header = string.format('%s: ', firstToUpper(v[1]))
      table.insert(rendered, header)
      extra_headers[v[1]] = nil
    elseif headers[v[1]] then
      local header = string.format('%s: %s', firstToUpper(v[1]), headers[v[1]])
      table.insert(rendered, header)
      extra_headers[v[1]] = nil
    end
  end

  self.extra_headers = extra_headers
  self:set_lines(0, 0, true, rendered)
end

function Compose:render_body(body)
  if body then
    self:set_lines(-1, -1, true, body)
  end
end

function Compose:populate(msg)
  self:clear()

  self:consume_headers(msg)
  local after = vim.fn.line('$') - 1
  self:render_body(msg.body)

  self:make_seperator(after)

  self:addfiles(msg.attachments)
end

-- change message to file
function Compose:create(kind, msg, opts)
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

      buffer.ns = vim.api.nvim_create_namespace('galore-attachments')
      buffer.compose = vim.api.nvim_create_namespace('galore-compose')
      buffer:populate(msg)

      buffer:set_option('modified', false)

      buffer:update_attachments()
      opts.init(buffer)
      buffer:commands()
    end,
  }, Compose)
end

return Compose
