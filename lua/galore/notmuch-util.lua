-- local nm = require("galore.notmuch")
local nm = require "notmuch"
local u = require "galore.util"
local hi = require "galore.history"

local M = {}

--- The thread will be freed on return, don't return the thread
--- @param message any a message
--- @param f function a function that takes a thread
--- @return any returns the value after running f
function M.message_with_thread(message, f)
  local id = nm.message_get_thread_id(message)
  local db = nm.message_get_db(message)
  local query = nm.create_query(db, "thread:" .. id)
  for thread in nm.query_get_threads(query) do
    return f(thread)
  end
end

--- Get a single message and convert it into a line
function M.get_message(message)
  local id = nm.message_get_id(message)
  local tid = nm.message_get_thread_id(message)
  local filenames = u.collect(nm.message_get_filenames(message))
  local sub = nm.message_get_header(message, "Subject")
  local tags = u.collect(nm.message_get_tags(message))
  local from = nm.message_get_header(message, "From")
  local date = nm.message_get_date(message)
  local key = u.collect(nm.message_get_properties(message, "session-key", true))
  return {
    id = id,
    tid = tid,
    filenames = filenames,
    level = 1,
    pre = "",
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
  local query = nm.create_query(db, "mid:" .. id)
  for thread in nm.query_get_threads(query) do
    local i = 1
    line.total = nm.thread_get_total_messages(thread)
    local iter = nm.thread_get_toplevel_messages(thread)
    pop_helper(line, iter, i)
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

--- @param db notmuch.Db
--- @param line_info table
function M.update_line(db, line_info)
  local message = nm.db_find_message(db, line_info.id)
  local new_info = M.get_message(message)
  line_info.id = new_info.id
  line_info.filenames = new_info.filenames
  line_info.tags = new_info.tags
end

return M
