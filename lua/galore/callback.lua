--- TODO, this file includes to much globally
local message_view = require('galore.message_view')
local thread_view = require('galore.thread_view')
local compose = require('galore.compose')
local nu = require('galore.notmuch-util')
local runtime = require('galore.runtime')
local config = require('galore.config')
local br = require('galore.browser')
local tm = require('galore.templates')
-- local nm = require("galore.notmuch")
local nm = require('notmuch')

local M = {}

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

--- this should be "global"?
function M.new_message(kind, opts)
  opts = opts or {}
  tm.compose_new(opts)
  compose:create(kind, opts)
end

-- move to browser
--- Change the tag for currently selected message and update the browser
--- @param browser any
--- @param tag string +tag to add tag, -tag to remove tag
function M.message_change_tag(browser, tag)
  local vline, id = br.select(browser)
  runtime.with_db_writer(function(db)
    nu.change_tag(db, id, tag)
    nu.tag_if_nil(db, id, config.values.empty_tag)
  end)
  browser:update(vline)
end

-- move to browser
--- Ask for a change the tag for currently selected message and update the browser
--- @param browser any
function M.message_change_tag_ask(browser)
  vim.ui.input({ prompt = 'Tags change: ' }, function(input)
    if input then
      M.change_tag(browser, input)
    else
      error('No tag')
    end
  end)
end

--- TODO: add update for other views?
function M.change_tags_threads(browser, tag)
  local vline, tid = browser.thread()
  runtime.with_db_writer(function(db)
    local q = nm.create_query(db, 'thread: ' .. tid)
    for thread in nm.query_get_threads(q) do
      for message in nm.thread_get_messages(thread) do
        local id = nm.message_get_id(message)
        nu.change_tag(db, id, tag)
        nu.tag_if_nil(db, id, config.value.empty_tag)
      end
    end
    if vline then
      browser:update(vline)
    end
  end)
end

-- move to browser
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
