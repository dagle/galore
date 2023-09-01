--- Creates marks from a line-info from either a view or a compose
local M = {}

local function mark(buffer, ns, content, line_num, id)
  local col_num = 0

  local opts = {
    virt_text = { { content, "GaloreHeader" } },
    id = id,
  }
  return vim.api.nvim_buf_set_extmark(buffer, ns, line_num, col_num, opts)
end

function M.tags(line)
  return string.format("(%s)", table.concat(line.tags, " "))
end

function M.index(line)
  return string.format("[%d/%d]", line.index, line.total)
end

M.Headers = {
  From = M.tags,
  Subject = M.index
}

function M.mark(key, buffer, ns, i, line)
  if M.Headers[key] and ns then
    local str = M.Headers[key](line)
    mark(buffer, ns, i, str)
  end
end

return M
