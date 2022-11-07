local gp = require('galore.gmime.parts')
local M = {}

--- hook design:
--- They should log when they run
--- A hook should be able to block and not.

function M.preview_ask(message)
  -- create preview
  vim.ui.input({
    prompt = 'Do you want to send email? [Y]es/[N]o',
  }, function(input)
    if input then
      input = input:lower()
      if input == 'yes' or input == 'y' then
        return true
      end
    end
    return false
  end)
end

--- @param message any
--- @return boolean
function M.has_attachment(message)
  local state = {}
  local find_attachment = function(_, part)
    if gp.is_part(part) and gp.part_is_attachment(part) then
      state.attachment = true
    end
  end
  gp.message_foreach(message, find_attachment)
  return state.attachment
end

--- Doesn't handle re:
function M.missed_attachment(message)
  local sub = gp.message_get_subject(message)
  if sub:match('[a,A]ttachment') and not M.has_attachment(message) then
    return false
  end
  return true
end

-- Delay sending for X seconds
-- Returns a cancel channel and a delay-hook
-- XXX api for async hooks?
-- You don't use this directly but to make hooks
function M.make_delay_hook(seconds) end

return M
