-- Module to handle session keys.

local nm = require "notmuch"
local rt = require "galore.runtime"
local M = {}

-- Contains session keys
local manager = {}

--- Compares 2 lists and returns true if both lists are equal
--- @param t1 string[]
--- @param t2 string[]
local function equal(t1, t2)
  if #t1 ~= t2 then
    return false
  end
  for i = 1, #t1 do
    if t1[i] ~= t2[i] then
      return false
    end
  end
  return true
end

--- @param mid string message id
--- @param sk string[] session-key we can use to decrypt message.
--- @return boolean update returns true if the key is updated
function M.update_key(mid, sk)
  if equal(manager[mid], sk) then
    return false
  end
  manager[mid] = sk
  return true
end

function M.clear_key(mid)
  manager[mid] = nil
end

--- @param mid string message id
--- @return string[]? session-key get the session-key
function M.get_key(mid)
  if not manager[mid] then
    rt.with_db(function(db)
      local message = nm.db_find_message(db, mid)
      local sk = nm.message_get_property(message, "session-key")
      manager[mid] = sk
    end)
  end
  return manager[mid]
end

--- Writes a mid in the manager back to the notmuch database
--- @param mid string message id
function M.write_back(mid)
  if manager[mid] then
    rt.with_db_writer(function(db)
      local message = nm.db_find_message(db, mid)
      nm.message_add_property(message, "session-key", manager[mid])
    end)
  end
end

--- Writes all saved keys manager back to the notmuch database
function M.write_back_all()
  rt.with_db_writer(function(db)
    for mid, sk in pairs(manager) do
      local message = nm.db_find_message(db, mid)
      nm.message_add_property(message, "session-key", sk)
    end
  end)
end

return M
