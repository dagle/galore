local History = {}

local history = {}

function History.get_bufnr(bufnr)
  if bufnr == 0 then
    bufnr = vim.fn.bufnr()
  end

  history[bufnr] = history[bufnr] or {}
  return history[bufnr]
end

function History.push_local(bufnr, changelist)
  if not bufnr or not changelist or vim.tbl_isempty(changelist) then
    return
  end

  local buf = History.get_bufnr(bufnr)
  table.insert(buf, changelist)
end

function History.pop_local(bufnr)
  local buf = History.get_bufnr(bufnr)
  if vim.tbl_isempty(buf) then
    return
  end

  return table.remove(buf, #buf)
end

return History
