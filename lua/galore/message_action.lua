-- these are functions that work on messages
-- these should functions work on views (thread and message-view), browsers (tmb and message)
-- and telescope.

local nm = require "notmuch"
local nu = require "galore.notmuch-util"
local runtime = require "galore.runtime"
local gu = require "galore.gmime-util"
local tm = require "galore.compose.templates"
local compose = require "galore.compose.compose"

local M = {}

--- Create a reply compose from a message view
--- @param message gmime.Message
--- @param mode 'reply' | 'reply_all'
-- @param opts any
function M.message_reply(kind, message, mode, opts)
  opts = opts or {}
  opts.reply = true
  mode = mode or "reply"

  local msg = tm.response_message(message, opts, mode)
  --- create a msg
  msg:load_body(message, opts)
  msg.attachments = nil

  -- tm.response_message(message, opts, mode)
  gu.make_ref(message, msg)
  compose:create(kind, msg, opts)
end

--- Create a reply compose from a message view
--- @param message gmime.Message
--- @param opts any
function M.load_draft(kind, message, opts)
  opts = opts or {}
  local msg
  tm.load_body(message, opts)
  tm.load_headers(message, opts)
  msg.mid = message:get_message_id(message)

  compose:create(kind, opts)
end

function M.mid_reply(kind, mid, mode, opts)
  local line
  opts = opts or {}
  runtime.with_db(function(db)
    local nm_message = nm.db_find_message(db, mid)
    line = nu.get_message(nm_message)
  end)
  local draft = vim.tbl_contains(line.tags, "draft")
  local message = gu.parse_message(line.filenames[1])
  if message == nil then
    error "Couldn't parse message"
  end
  if draft then
    M.load_draft(kind, message, opts)
  else
    M.message_reply(kind, message, mode, opts)
  end
end

function M.get_tid(mid)
  local id
  runtime.with_db(function(db)
    local nm_message = nm.db_find_message(db, mid)
    id = nm.message_get_thread_id(nm_message)
  end)
  return id
end

-- function M.send_template(opts)
--   local buf = { headers = opts.headers, body = opts.Body }
--   local send_opts = {}
--   local message = builder.create_message(buf, send_opts, opts.Attach, {}, builder.textbuilder)
--   -- something like this
--   -- job.send_mail(message, function ()
--   -- end
-- end

return M
