local History = {}

local history = {}

local function get_bufnr(bufnr)
  if type(bufnr) == "nil" then
    return vim.fn.bufnr()
  end
  return vim.fn.bufnr(bufnr)
end

--- @param bufnr number
--- @return string[][]?
--- Returns the history buffer (or nil) for bufnr, if bufnr is 0, current buffer is returned
function History.get_bufnr(bufnr)
  bufnr = get_bufnr(bufnr)

  if bufnr <= 0 then
    return nil
  end

  return history[bufnr]
end

--- @param bufnr number
--- @param changelist string[]
--- commit a changeset to history. A changeset is a list of change
--- {"+tag1", "-tag2"}.
function History.push_local(bufnr, changelist)
  if not bufnr or not changelist or vim.tbl_isempty(changelist) then
    return
  end
  bufnr = get_bufnr(bufnr)

  if bufnr <= 0 then
    return
  end

  local buf = history[bufnr] or {}
  table.insert(buf, changelist)
  vim.print(bufnr)
  history[bufnr] = buf
end

--- @param bufnr number
--- @return history_entry|nil
--- pop a changeset from history.
function History.pop_local(bufnr)
  local buf = History.get_bufnr(bufnr)
  if not buf or vim.tbl_isempty(buf) then
    return
  end

  return table.remove(buf, #buf)
end

--- @param bufnr number?
--- Clears history for bufnr or all buffers if bufnr isn't set
function History.clear(bufnr)
  if bufnr then
    history[bufnr] = nil
  else
    history = {}
  end
end

--- debug function to show what we have in the history
function History.show()
  vim.print(history)
end

return History
