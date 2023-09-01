--- A module for users to "debug" email messages.
--- It can be used by users to be sure email gets formated correctly into a mime.
--- You could build an interface like mutt that lets you preview before sending.

local nm = require('notmuch')
local runtime = require('galore.runtime')
local Buffer = require('galore.lib.buffer')
local gu = require('galore.gmime-util')
local uv = vim.loop

local gmime = require("galore.gmime")

local debug = {}

--- TODO: Why?

--- Functions to aid in debugging.
--- Atm it's just functions to view raw messages
---@param filename string
---@param kind any?  TODO: create a smode enum
function debug.view_raw_file(filename, kind)
  Buffer.create({
    ft = 'mail',
    kind = kind or 'floating',
    cursor = 'top',
    init = function(buffer)
      local fd = assert(uv.fs_open(filename, 'r', 438))
      local stat = assert(uv.fs_fstat(fd))
      local data = assert(uv.fs_read(fd, stat.size, 0))
      assert(uv.fs_close(fd))
      data = vim.split(data, '\n')
      buffer:set_lines(0, 0, true, data)
    end,
  })
end

--- requires that the message is in the notmuch db
---@param mid string
---@param kind any?
function debug.view_raw_mid(mid, kind)
  local filename
  runtime.with_db(function(db)
    local message = nm.db_find_message(db, mid)
    filename = nm.message_get_filename(message)
  end)
  debug.view_raw_file(filename, kind)
end

--- maybe not do this for really big files? Maybe keep a cap?
---@param attachment Attachment
---@param kind any?
function debug.view_raw_attachment(attachment, kind)
  Buffer.create({
    ft = attachment.mime_type,
    kind = kind or 'floating',
    cursor = 'top',
    init = function(buffer)
      local buf
      if attachment.part then
        buf = gu.part_to_string(attachment.part)
      elseif attachment.data then
        buf = attachment.data
      else
        local fd = assert(uv.fs_open(attachment.filename, 'r', 438))
        local stat = assert(uv.fs_fstat(fd))
        buf = assert(uv.fs_read(fd, stat.size, 0))
        assert(uv.fs_close(fd))
      end
      local fixed = vim.split(buf, '\n')
      buffer:set_lines(0, 0, true, fixed)
    end,
  })
end

--- maybe not do this for really big files? Maybe keep a cap?
---@param message GMime.Message
---@param kind any?
function debug.view_raw_message(message, kind)
  if not message then
    return
  end
  local mem = gmime.StreamMem.new()
  message:write_to_stream(nil, mem)
  mem:flush()
  local str = mem:get_byte_array()
  local tbl = vim.split(str, '\n')
  Buffer.create({
    ft = 'mail',
    kind = kind or 'floating',
    cursor = 'top',
    init = function(buffer)
      buffer:set_lines(0, 0, true, tbl)
    end,
  })
end

return debug
