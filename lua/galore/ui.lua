-- UI functions that works in multiple kinds browsers.

local M = {}

--- Adds the attachments in the bottom of the buffer
--- It doesn't render the attachment it self but rather a filename.
---@param attachments Attachment
---@param line any
---@param buffer any
---@param ns any
function M.render_attachments(attachments, line, buffer, ns)
  if #attachments == 0 then
    return
  end
  local marks = {}
  for _, v in ipairs(attachments) do
    local str = string.format('- [%s]', v.filename)
    table.insert(marks, { str, 'GaloreAttachment' })
  end
  local opts = {
    virt_lines = {
      marks,
    },
  }
  vim.api.nvim_buf_set_extmark(buffer, ns, line, 0, opts)
end

function M.extmark(buf, ns, style, text, line)
  -- for now
  if not ns then
    return
  end
  local opts = {
    virt_lines = {
      { { text, style } },
    },
  }
  vim.api.nvim_buf_set_extmark(buf, ns, line, 0, opts)
end

return M
