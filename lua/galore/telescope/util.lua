local ts_utils = require('telescope.utils')
local strings = require('plenary.strings')

local M = {}

-- Something like like this.
-- Should take a hight because not all of the
-- email might be encrypted etc
function M.encrypted(buf, winid, message)
  local height = vim.api.nvim_win_get_height(winid)
  local width = vim.api.nvim_win_get_width(winid)
  local fillchar = '╱'
  vim.api.nvim_buf_set_lines(
    buf,
    -1,
    -1,
    false,
    ts_utils.repeated_table(height, table.concat(ts_utils.repeated_table(width, fillchar), ''))
  )
  local anon_ns = vim.api.nvim_create_namespace('')
  local padding = table.concat(ts_utils.repeated_table(#message + 4, ' '), '')
  local lines = {
    padding,
    '  ' .. message .. '  ',
    padding,
  }
  vim.api.nvim_buf_set_extmark(
    buf,
    anon_ns,
    0,
    0,
    { end_line = height, hl_group = 'TelescopePreviewMessageFillchar' }
  )
  local col = math.floor((width - strings.strdisplaywidth(lines[2])) / 2)
  for i, line in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(
      buf,
      anon_ns,
      math.floor(height / 2) - 1 + i,
      0,
      {
        virt_text = { { line, 'TelescopePreviewMessage' } },
        virt_text_pos = 'overlay',
        virt_text_win_col = col,
      }
    )
  end
  --
end

function M.list_to_table(list)
  local tbl = {}
  for _, v in ipairs(list) do
    local key = v[1]
    local value = v[2]
    tbl[key] = value
  end
  return tbl
end

return M
