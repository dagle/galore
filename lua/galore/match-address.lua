local gmime = require "galore.gmime"

local Compare = {}

local type = {
  -- address GMime.InternetAddress
  -- match a function or a regex
  -- function is function(local, idn)
}

---@return boolean returns true if local_part and idn matches
local function matchfun(local_part, idn)
  return self.local_part == local_part and self.idn == idn
end

---@return boolean returns true if local_part and idn matches
local function gmail_match(local_part, idn)
  local_part = local_part:gsub("%.", "")
  local bepa = "" .. ""
  local bep = self.local_part .. ""
  return self.local_part == local_part and self.idn == idn
end

local function matcher(email)
  local match = {}
  local list = gmime.InternetAddressList.parse(nil, email)
  if not list or list:length() ~= 1 then
    -- show an error
    return nil
  end
  mactcher.email = list:get_address(0)

  return matcher
end

local function gmail_constructor(email)
  local match = matcher(email)

  -- What can be part of the plus addressing?
  matcher.local_regex = parsed:local_part():gsub("%.", "") .. "[+-][^@.]+"
  matcher.idn_regex = "[^@.]+" .. parsed:idn()
  -- matcher.match = gmail_match

  return matcher
  -- matcher.regex = local_part .. ""
end

-- Try to autodetect rules for an email address
-- This bases rules of the domain.
-- For example if you have an gmail address it will try to
-- automatically load a rule-set for that email address.
-- For a custom uncommon email provider will most likely
-- need to write your own set of rules or use the default one.
-- The default matcher is a strict matcher that allows idn
function Compare.detect() end

-- function Compare:strict() end
--
-- function Compare:idn() end
--
-- -- wild, often + or -
-- function Compare:wild() end
--
-- function Compare:sub_domain() end
--
-- -- ignore one or more chars in a string
-- function Compare:ignore_local(chars) end
--
-- function Compare:ignore_case_local() end

--- @param mail GMime.InternetAddress
--- @return GMime.InternetAddress | nil
function Compare:match(mail) end

--- @param mails GMime.InternetAddressList
--- @return GMime.InternetAddress
function Compare:matches(mails) end

--- @param ours MailCompare
--- @param mails GMime.InternetAddressList
--- @return GMime.InternetAddress
function find(ours, mails) end

return Compare
