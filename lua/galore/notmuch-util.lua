-- local nm = require("galore.notmuch")
local nm = require('notmuch')
local u = require('galore.util')
local hi = require('galore.history')

local M = {}

--- The thread will be freed on return, don't return the thread
--- @param message any a message
--- @param f function a function that takes a thread
--- @return any returns the value after running f
function M.message_with_thread(message, f)
  local id = nm.message_get_thread_id(message)
  local db = nm.message_get_db(message)
  local query = nm.create_query(db, 'thread:' .. id)
  for thread in nm.query_get_threads(query) do
    return f(thread)
  end
end

--- Get a single message and convert it into a line
function M.get_message(message)
  local id = nm.message_get_id(message)
  local tid = nm.message_get_thread_id(message)
  local filenames = u.collect(nm.message_get_filenames(message))
  local sub = nm.message_get_header(message, 'Subject')
  local tags = u.collect(nm.message_get_tags(message))
  local from = nm.message_get_header(message, 'From')
  local date = nm.message_get_date(message)
  local key = u.collect(nm.message_get_properties(message, 'session-key', true))
  return {
    id = id,
    tid = tid,
    filenames = filenames,
    level = 1,
    pre = '',
    index = 1,
    total = 1,
    date = date,
    from = from,
    sub = sub,
    tags = tags,
    key = key,
  }
end

local function pop_helper(line, iter, i)
  for message in iter do
    if line.id == nm.message_get_id(message) then
      line.index = i
      break
    end
    local new_iter = nm.message_get_replies(message)
    i = pop_helper(line, new_iter, i + 1)
  end
  return i
end

--- @param db ffi.cdata* a notmuch message
--- @param line number 
function M.line_populate(db, line)
  local id = line.id
  local query = nm.create_query(db, 'mid:' .. id)
  for thread in nm.query_get_threads(query) do
    local i = 1
    line.total = nm.thread_get_total_messages(thread)
    local iter = nm.thread_get_toplevel_messages(thread)
    pop_helper(line, iter, i)
  end
end

--- @param message ffi.cdata* a notmuch message
--- @param tag string tag to delete
--- @param history table?
--- Wrapper around message_add_tag that adds the inversion
--- to a history buffer if it's not null.
--- If the tag is found this function doesn't do anything
--- and history isn't updated.
local function add_tag(message, tag, history)
  if history then
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

--- @param message ffi.cdata* a notmuch message
--- @param tag string tag to delete
--- @param history table?
--- Wrapper around message_remove_tag that adds the inversion
--- to a history buffer if it's not null.
--- If the tag is not found this function doesn't do anything
--- and history isn't updated.
local function del_tag(message, tag, history)
  local found = false
  if history then
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
    if not (op == '+' or op == '-') then
      return false
    end
  end
  return true
end

--- @param message ffi.cdata* a notmuch message
--- @param changes string[]
--- @param history table?
--- changes tags for message, adds it to the history if it made a change.
--- if the tag already had the tag (for +tag) or didn't have the tag (for -tag),
--- this becomes a nop and history isn't updated.
local function update_tags(message, changes, history)
  nm.message_freeze(message)
  for _, change in ipairs(changes) do
    local op = string.sub(change, 1, 1)
    local tag = string.sub(change, 2)
    if op == '-' then
      del_tag(message, tag, history)
    elseif op == '+' then
      add_tag(message, tag, history)
    end
  end
  nm.message_thaw(message)
  nm.message_tags_to_maildir_flags(message)
end

--- @param db ffi.cdata* notmuch db connection
--- @param id string a notmuch message id
--- @param tag_changes string tags we want to change for the query
--- @param bufnr number? bufnr (0 for current) we want to add this to history
function M.change_tag(db, id, tag_changes, bufnr)
  local history
  if bufnr then
    history = {}
  end

  local changes = vim.split(tag_changes, ' ')
  if not verify_changes(changes) then
    vim.notify("The tag changing string is of the wrong format", vim.log.levels.ERROR)
    return
  end
  local message = nm.db_find_message(db, id)
  if message == nil then
    vim.notify("Can't change tag, message not found", vim.log.levels.ERROR)
    return
  end
  nm.db_atomic_begin(db)
  update_tags(message, changes, history)
  nm.db_atomic_end(db)
  if bufnr then
    hi.push_local(bufnr, history)
  end
end

--- @param db ffi.cdata* notmuch db connection
--- @param query string a notmuch query
--- @param tag_changes string tags we want to change for the query
--- @param bufnr number? bufnr (0 for current) we want to add this to history
function M.change_tag_query(db, query, tag_changes, bufnr)
  local history
  if bufnr then
    history = {}
  end

  local changes = vim.split(tag_changes, ' ')
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

--- @param db ffi.cdata* notmuch db connection
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
  if vim.tbl_isempty(tags) then
    M.change_tag(db, id, tag)
  end
end

--- @param db ffi.cdata* notmuch db connection
--- @param bufnr number a bufnr or 0 for current buffer
--- Reverts the last tag changeset for the buffer
function M.undo(db, bufnr)
  local bufchanges = hi.pop_local(bufnr)
  if not bufchanges then
    return
  end

  -- should we add a redo?
  for action in ipairs(bufchanges) do
    local message = nm.db_find_message(db, action.mid)
    -- if we don't find the message, we just ignore it.
    if message then
      nm.db_atomic_begin(db)
      update_tags(message, action.changes)
      nm.db_atomic_end(db)
    end
  end
end

--- @param db ffi.cdata* notmuch db connection
--- @param line_info number
function M.update_line(db, line_info)
  local message = nm.db_find_message(db, line_info.id)
  local new_info = M.get_message(message)
  line_info.id = new_info.id
  line_info.filenames = new_info.filenames
  line_info.tags = new_info.tags
end

return M
