--- TODO, this file includes to much globally
local message_view = require('galore.message_view')
local thread_view = require('galore.thread_view')
local compose = require('galore.compose')
local gu = require('galore.gmime-util')
local nu = require('galore.notmuch-util')
local runtime = require('galore.runtime')
local config = require('galore.config')
local br = require('galore.browser')
local tm = require('galore.templates')
-- local nm = require("galore.notmuch")
local nm = require('notmuch')

local M = {}

--- Select a saved search and open it in specified browser and mode
--- @param saved any
--- @param browser any
--- @param mode any
function M.select_search(saved, browser, mode)
  local search = saved:select()[4]
  browser:create(search, { kind = mode, parent = saved })
end

function M.select_search_default(saved, mode)
  local default_browser = saved.opts.default_browser or 'tmb'
  local browser
  if default_browser == 'tmb' then
    browser = require('galore.thread_message_browser')
  elseif default_browser == 'message' then
    browser = require('galore.message_browser')
  elseif default_browser == 'thread' then
    browser = require('galore.thread_browser')
  end
  M.select_search(saved, browser, mode)
end

--- Open the selected mail in the browser for viewing
--- @param browser any
--- @param mode any
function M.select_message(browser, mode)
  local vline, line_info = br.select(browser)
  message_view:create(line_info, { kind = mode, parent = browser, vline = vline })
end

--- Open the selected thread in the browser for viewing
--- @param browser any
--- @param mode any
function M.select_thread(browser, mode)
  local vline, line_info = browser:select_thread()
  thread_view:create(line_info, { kind = mode, parent = browser, vline = vline })
end

--- Yank the current line using the selector
--- @param browser any
function M.yank_browser(browser)
  local _, id = br.select(browser)
  vim.fn.setreg('', id)
end

--- Yank the current message using the selector
--- @param mv any
--- @param select any
--- TODO change, we only save mid!
function M.yank_message(mv, select)
  vim.fn.setreg('', mv.line[select])
end

function M.new_message(kind, opts)
  opts = opts or {}
  tm.compose_new(opts)
  compose:create(kind, opts)
end

--- load a message as it is
function M.load_draft(kind, message, opts)
  opts = opts or {}
  tm.load_body(message, opts)
  tm.load_headers(message, opts)
  opts.mid = message:get_message_id(message)
  compose:create(kind, opts)
end

--- Create a reply compose from a message view
--- @param message gmime.Message
--- @param opts any
function M.message_reply(kind, message, mode, opts)
  opts = opts or {}
  opts.reply = true
  mode = mode or 'reply'
  tm.load_body(message, opts)
  opts.Attach = nil
  tm.response_message(message, opts, mode)
  -- tm.response_message(message, opts, mode)
  gu.make_ref(message, opts)
  compose:create(kind, opts)
end

function M.send_template(opts)
  local buf = { headers = opts.headers, body = opts.Body }
  local send_opts = {}
  local message = builder.create_message(buf, send_opts, opts.Attach, {}, builder.textbuilder)
  -- something like this
  -- job.send_mail(message, function ()
  -- end
end

function M.mid_reply(kind, mid, mode, opts)
  local line
  opts = opts or {}
  runtime.with_db(function(db)
    local nm_message = nm.db_find_message(db, mid)
    line = nu.get_message(nm_message)
  end)
  local draft = vim.tbl_contains(line.tags, 'draft')
  local message = gu.parse_message(line.filenames[1])
  if message == nil then
    error("Couldn't parse message")
  end
  if draft then
    M.load_draft(kind, message, opts)
  else
    M.message_reply(kind, message, mode, opts)
  end
end

--- Change the tag for currently selected message and update the browser
--- @param browser any
--- @param tag string +tag to add tag, -tag to remove tag
function M.change_tag(browser, tag)
  local vline, id = br.select(browser)
  if tag then
    runtime.with_db_writer(function(db)
      nu.change_tag(db, id, tag)
      nu.tag_if_nil(db, id, config.values.empty_tag)
    end)
    browser:update(vline)
  end
end

--- Ask for a change the tag for currently selected message and update the browser
--- @param browser any
function M.change_tag_ask(browser)
  vim.ui.input({ prompt = 'Tags change: ' }, function(tag)
    if tag then
      M.change_tag(browser, tag)
    else
      error('No tag')
    end
  end)
end

function M.change_tags_threads(tb, tag)
  local vline, thread = br.select(tb)
  runtime.with_db_writer(function(db)
    local q = nm.create_query(db, 'thread:' .. thread)
    for message in nm.thread_get_messages(thread) do
      local id = nm.message_get_id(message)
      nu.change_tag(db, id, tag)
      nu.tag_if_nil(db, id, config.value.empty_tag)
    end
    tb:update(vline)
  end)
end

--- Ask for a change the tag for currently selected message and update the browser
--- @param tb any
function M.change_tag_threads_ask(tb)
  vim.ui.input({ prompt = 'Tags change: ' }, function(tag)
    if tag then
      M.change_tags_threads(tb, tag)
    else
      error('No tag')
    end
  end)
end

return M
