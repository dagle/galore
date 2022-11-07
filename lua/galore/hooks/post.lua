--- After a mail have been sent
local go = require('galore.gmime.object')
-- Should config really be in here?
local config = require('galore.config')
local job = require('galore.jobs')
local ffi = require('ffi')

local M = {}

-- XXX do error handling.
function M.fcc_nm_insert(message)
  local obj = ffi.cast('GMimeObject *', message)
  local fcc_str = go.object_get_header(obj, 'Fcc')

  -- Should we try to guard users?
  -- this shouldn't be an abs path
  local path = config.values.fccdir .. '/' .. fcc_str

  go.object_set_header(obj, 'Fcc', nil)
  job.insert_mail(message, path, '')
end

--- write file to a maildir
--- this should do a lot more checks
--- create dirs etc if it doesn't exist
function M.fcc_fs(message)
  local obj = ffi.cast('GMimeObject *', message)
  local fcc_str = go.object_get_header(obj, 'Fcc')

  go.object_set_header(obj, 'Fcc', nil)
end

function M.delete_draft(message) end

return M
