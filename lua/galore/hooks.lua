--- A hook takes a message and returns a boolean if success
local config = require('galore.config')
local job = require('galore.jobs')

local gmime = require("galore.gmime")

local M = {}

-- A pre hook is always return a boolean. If a pre hook return false

--- @param message any
--- @return boolean
local function has_attachment(message)
  local state = {}
  local find_attachment = function(_, part, _)
    if gmime.Part:is_type_of(part) and part:is_attchment(part) then
      state.attachment = true
    end
  end
  message:foreach(find_attachment)
  return state.attachment
end

--- Pre sending, check for attachments
--- @return boolean
function M.missed_attachment(message)
  local sub = message:get_subject()
  local start, _ = string.find(sub, '[a,A]ttachment')
  local re, _ = string.find(sub, '^%s*Re:')
  if start and not re and not has_attachment(message) then
    return false
  end
  return true
end

--- Pre sending, ask if you want to send the email
--- Should be in general be inserted before IO functions (like FCC)
--- @return boolean
function M.confirm()
  local ret = false
  vim.ui.input({
    prompt = 'Wanna send email? Y[es]',
  }, function(input)
    if input then
      input = input:lower()
      if input == 'yes' or 'y' then
        ret = true
      end
    end
  end)
  return ret
end

--- @return boolean
function M.fcc_nm_insert(message)
  local fcc_str = message:get_header('FCC')
  message:remove_header('FCC')

  -- Should we try to guard users?
  -- this shouldn't be an abs path
  local path = config.values.fccdir .. '/' .. fcc_str

  job.insert_mail(message, path, '')
end

--- write file to a maildir
--- this should do a lot more checks
--- create dirs etc if it doesn't exist

--- Pre send, insert the mail into fcc dir and then remove FCC header
--- @param message
--- @return boolean
function M.fcc_fs(message)
  local fcc_str = message:get_header('FCC')
  message:remove_header('FCC')
end

function M.preview() end

---

function M.delete_draft() end

return M
