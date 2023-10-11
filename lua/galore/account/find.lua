local gmime = require("galore.gmime")
local match = require("galore.account.match")

local M = {}

--- @param mail GMime.InternetAddress
--- @return GMime.InternetAddress | nil
function M.match(matcher, mail)
  --- if it is a group mail, we search for it there
  if gmime.InternetAddressGroup:is_type_of(mail) then
    local list = mail:get_members() --@as GMime.InternetAddressList
    for i = 0, list:length() do
      local grp_mail = list:get_address(i)
      local matched = M.match(self, grp_mail)
      if matched ~= nil then
        return matched
      end
    end
  end

  local str = mail:get_idn_addr()
  local local_part = string.sub(str, 1, mail.at)
  local idn = string.sub(str, mail.at+2)

  if matcher:matchfun(local_part, idn) then
    return mail
  end
end

--- @param mails GMime.InternetAddressList
--- @return GMime.InternetAddress | nil
function M.matches(matcher, mails)
  for i = 0, mails:length() do
    local mail = mails:get_address(i)
    local matched = M.match(matcher, mail)
    if matched ~= nil then
      return matched
    end
  end
end

--- @param accounts Account[]
--- @param mails GMime.InternetAddressList
--- @return GMime.InternetAddress| nil, Account | nil
function M.find(accounts, mails)
  for _, acc in ipairs(accounts) do
    local matched = M.matches(acc.match, mails)
    if matched ~= nil then
      return matched, acc
    end
  end
  return nil
end

return M
