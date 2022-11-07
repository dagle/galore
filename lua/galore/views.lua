local Path = require('plenary.path')
local gu = require('galore.gmime-util')
local runtime = require('galore.runtime')
local M = {}

--- TODO

function M.save_attachment(attachments, idx, save_path, overwrite)
  if attachments[idx] then
    local filename = attachments[idx].filename
    local path = Path:new(save_path)
    if path:is_dir() then
      path = path:joinpath(filename)
    end
    if path:exists() and not overwrite then
      error('file exists')
      return
    end
    gu.save_part(attachments[idx].part, path:expand())
    return
  end
  vim.api.nvim_err_writeln('No attachment with that name')
end

function M.select_attachment(attachments, cb)
  local files = {}
  for _, v in ipairs(attachments) do
    table.insert(files, v.filename)
  end
  vim.ui.select(files, {
    prompt = 'Select attachment: ',
  }, function(item, idx)
    if item then
      cb(attachments[idx])
    else
      vim.api.nvim_err_writeln('No file selected')
    end
  end)
end

local function mark_read(self, pb, line, vline)
  runtime.with_db_writer(function(db)
    self.opts.tag_unread(db, line.id)
    nu.tag_if_nil(db, line.id, self.opts.empty_tag)
    --- this doesn't work because we can't redraw just a message but the whole thread?
    --- Maybe redraw the whole thread?
    nu.update_line(db, pb, line, vline)
  end)
end

return M
