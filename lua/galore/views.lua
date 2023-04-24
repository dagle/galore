local Path = require('plenary.path')
local gu = require('galore.gmime-util')
local runtime = require('galore.runtime')
local nu = require('galore.notmuch-util')
local M = {}

--- TODO

local function save_attachment(attachment, save_path, confirm)
  if not attachment then
    -- log.error("No attachment with that name")
    return
  end

  local filename = attachment.filename
  local path = Path:new(save_path)
  if path:is_dir() then
    path = path:joinpath(filename)
  end
  if path:exists() and confirm then
    vim.ui.input({
      prompt = "File exist, do you want to overwrite it? [y/N]",
      default = "no",
    }, function (resp)
      resp = resp:lower()
      if not (resp == "y" or resp == "yes") then
        return
      end
    end)
  end
  gu.save_part(attachment.part, path:expand())
end

function M.save_attachment(attachments, name, save_path, overwrite)
  local attachment

  for _, attach in ipairs(attachments) do
    if attach.filename == name then
      attachment = attach
      break
    end
  end

  save_attachment(attachment, save_path, overwrite)
end

function M.save_attachment_index(attachments, index, save_path, overwrite)
  local attachment = attachments[index]
  save_attachment(attachment, save_path, overwrite)
end

--- Yank the current message using the selector
--- @param mv any
--- @param select any
--- TODO change, we only save mid!
function M.yank_message(mv, select)
  vim.fn.setreg('', mv.line[select])
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
