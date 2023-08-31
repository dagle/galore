local nu = require "galore.notmuch-util"
local runtime = require "galore.runtime"
local nm = require "notmuch"
local hi = require "galore.history"

local M = {}

--- @param browser any
--- @param change string +tag to add tag, -tag to remove tag
--- Change the tag for currently selected message and update the browser
function M.message_change_tags(browser, change, empty_tag)
  local vline, id = browser:message()
  runtime.with_db_writer(function(db)
    nu.change_tag(db, id, change, 0)
    nu.tag_if_nil(db, id, empty_tag)
  end)
  -- todo only do this if the tag has changed
  browser:update_message(vline)
end

function M.message_change_tag_ask(browser)
  vim.ui.input({ prompt = "Tags change: " }, function(input)
    if input then
      M.message_change_tags(browser, input)
    else
      error "No tag"
    end
  end)
end

--- @param browser any
--- @param change string +tag to add tag, -tag to remove tag
--- Change the tag for currently selected entry's thread and update the browser
function M.threads_change_tags(browser, change)
  local vline, tid = browser:thread()
  runtime.with_db_writer(function(db)
    nu.change_tag_query(db, "thread: " .. tid, change, 0)
    if vline then
      --- this can be multiple lines, so we can't update just the current line
      browser:update_thread(vline)
    end
  end)
end

--- Ask for a change the tag for currently selected message and update the browser
--- @param browser any
function M.change_tag_threads_ask(browser)
  vim.ui.input({ prompt = "Tags change: " }, function(tag)
    if tag then
      M.change_tags_threads(browser, tag)
    else
      error "No tag"
    end
  end)
end

--- @param message notmuch.Message
--- @param tag string tag to delete
--- @param history table?
--- Wrapper around message_add_tag that adds the inversion
--- to a history buffer if it's not null.
--- If the tag is found this function doesn't do anything
--- and history isn't updated.
local function add_tag(message, tag, history)
  if history then
    --- TODO: move this to the upper function
    for have in nm.message_get_tags(message) do
      if have == tag then
        return
      end
    end
  end

  local status = nm.message_add_tag(message, tag)
  if status then
    -- TODO: status here
    return status
  end
  if history then
    -- insert the inverse into history
    table.insert(history, "-" .. tag)
  end
end

--- @param message notmuch.Message
--- @param tag string tag to delete
--- @param history table?
--- Wrapper around message_remove_tag that adds the inversion
--- to a history buffer if it's not null.
--- If the tag is not found this function doesn't do anything
--- and history isn't updated.
local function del_tag(message, tag, history)
  local found = false
  if history then
    --- TODO: move this to the upper function
    for have in nm.message_get_tags(message) do
      if have == tag then
        found = true
      end
    end

    if not found then
      return
    end
  end

  local status = nm.message_remove_tag(message, tag)
  if status then
    -- TODO: status here
    return status
  end
  if history then
    -- insert the inverse into history
    table.insert(history, "+" .. tag)
  end
end

--- @param changes string[]
--- @return boolean
--- Check if all changes follows the format
--- "+|-name" etc
local function verify_changes(changes)
  for _, change in ipairs(changes) do
    local op = string.sub(change, 1, 1)
    if not (op == "+" or op == "-") then
      return false
    end
  end
  return true
end

--- changes tags for message, adds it to the history if it made a change.
--- if the tag already had the tag (for +tag) or didn't have the tag (for -tag),
--- this becomes a nop and history isn't updated.
--- @param message notmuch.Message notmuch db connection
--- @param changes string[]
--- @param history table?
--- @return boolean #returns true if the function changed a tag
local function update_tags(message, changes, history)
  nm.message_freeze(message)
  for _, change in ipairs(changes) do
    local op = string.sub(change, 1, 1)
    local tag = string.sub(change, 2)
    if op == "-" then
      del_tag(message, tag, history)
    elseif op == "+" then
      add_tag(message, tag, history)
    end
  end
  nm.message_thaw(message)
  nm.message_tags_to_maildir_flags(message)
end

--- @param db notmuch.Db notmuch db connection
--- @param id string a notmuch message id
--- @param tag_changes string tags we want to change for the query
--- @param bufnr number? bufnr (0 for current) we want to add this to history
--- @return boolean #returns true if the function changed a tag
function M.change_tag(db, id, tag_changes, bufnr)
  local changed = false
  local history
  if bufnr then
    history = {}
  end

  local changes = vim.split(tag_changes, " ")
  if not verify_changes(changes) then
    vim.notify("The tag changing string is of the wrong format", vim.log.levels.ERROR)
    return false
  end
  local message = nm.db_find_message(db, id)
  if message == nil then
    vim.notify("Can't change tag, message not found", vim.log.levels.ERROR)
    return false
  end
  nm.db_atomic_begin(db)
  changed = update_tags(message, changes, history)
  nm.db_atomic_end(db)
  if bufnr then
    hi.push_local(bufnr, history)
  end
  return changed
end

--- @param db notmuch.Db notmuch db connection
--- @param query string a notmuch query
--- @param tag_changes string tags we want to change for the query
--- @param bufnr number? bufnr (0 for current) we want to add this to history
function M.change_tag_query(db, query, tag_changes, bufnr)
  local history
  if bufnr then
    history = {}
  end

  local changes = vim.split(tag_changes, " ")
  if not verify_changes(changes) then
    vim.notify("The tag changing string is of the wrong format", vim.log.levels.ERROR)
    return
  end
  local q = nm.create_query(db, query)
  if not q then
    vim.notify("Can't change tag, bad query not found", vim.log.levels.ERROR)
    return
  end
  for message in nm.query_get_messages(q) do
    nm.db_atomic_begin(db)
    update_tags(message, changes, history)
    nm.db_atomic_end(db)
  end
  if bufnr then
    hi.push_local(bufnr, history)
  end
end

--- @param db notmuch.Db notmuch db connection
--- @param id string a notmuch id
--- @param tag string? a default tag.
--- Set a default tag if the all tags are removed. This is useful because trying to browse
--- messages without tags can be annoying. A common thing is to is to set messages without any
--- tags to be archived.
function M.tag_if_nil(db, id, tag)
  if not tag then
    return
  end
  local message = nm.db_find_message(db, id)
  local tags = u.collect(nm.message_get_tags(message))
  -- local tags = vim.iter(nm.message_get_tags(message)):collect()
  if vim.tbl_isempty(tags) then
    M.change_tag(db, id, tag)
  end
end

return M
