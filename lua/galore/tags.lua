local nu = require('galore.notmuch-util')
local runtime = require('galore.runtime')

local M = {}

--- @param browser any
--- @param change string +tag to add tag, -tag to remove tag
--- Change the tag for currently selected message and update the browser
function M.message_change_tag(browser, change)
  local vline, id = browser:message()
  runtime.with_db_writer(function(db)
    nu.change_tag(db, id, change, 0)
    -- nu.tag_if_nil(db, id, config.values.empty_tag)
  end)
  browser:update(vline)
end

function M.message_change_tag_ask(browser)
  vim.ui.input({ prompt = 'Tags change: ' }, function(input)
    if input then
      M.message_change_tag(browser, input)
    else
      error('No tag')
    end
  end)
end

--- @param browser any
--- @param change string +tag to add tag, -tag to remove tag
--- Change the tag for currently selected entry's thread and update the browser
function M.change_tags_threads(browser, change)
  local vline, tid = browser.thread()
  runtime.with_db_writer(function(db)
    nu.change_tag_query(db, 'thread: ' .. tid, change, 0)
    if vline then
      --- this can be multiple lines, so we can't update just the current line
      browser:update(vline)
    end
  end)
end

--- Ask for a change the tag for currently selected message and update the browser
--- @param browser any
function M.change_tag_threads_ask(browser)
  vim.ui.input({ prompt = 'Tags change: ' }, function(tag)
    if tag then
      M.change_tags_threads(browser, tag)
    else
      error('No tag')
    end
  end)
end

return M
