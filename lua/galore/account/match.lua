local Match = {}
--- Matcher is a class for matching 2 emails. Mostly
--- used to figure out what email address was used to send an email.
--- 
--- You create an matcher during startup (by default it will try 
--- the detector if no constructor is specifed). 
---
--- local compare = require("galore.account.match")

--- @class Matcher
--- @field email GMime.InternetAddressMailbox
--- @field local_part string
--- @field idn string
--- @field matchfun function(string, string)

---@return boolean returns true if local_part and idn matches
function Match:strict_match(local_part, idn)
  -- should we ignore case by default?
  return self.local_part == local_part and self.idn == idn
end

function Match.matcher(email)
  local match = {}

  local str = email:get_idn_addr()
  match.local_part = string.sub(str, 1, email.at)
  match.idn = string.sub(str, email.at+2)

  match.matchfun = Match.strict_match

  return match
end

function Match.regex_compare(self, local_part, idn)
  local l_start, l_stop = self.local_regex:match_str(local_part)
  local i_start, i_stop = self.idn_regex:match_str(idn)
  return l_start == 0 and l_stop == #local_part and i_start == 0 and i_stop == #idn
end

function Match:gmail_match(local_part, idn)
  local_part = local_part:gsub("%.", "")

  return Match.regex_compare(self, local_part, idn)
end

--- @param idn string 
--- @return string
function Match.Subdomain(idn)
  return "\\(\\w\\+.\\)\\?" .. idn
end

--- @param local_part string 
--- @param signs string|nil what we accept for wilds, "+" by default
--- @return string
function Match.Wild(local_part, signs)
  signs = signs or "+"
  return string.format("%s\\([%s]\\w\\+\\)\\?", local_part, signs)
end

function Match.gmail(email)
  local match = Match.matcher(email)

  -- we don't care about case, dots are optional and wilds are accepted on "+"
  match.local_regex = vim.regex("\\c" .. Match.Wild((match.local_part:gsub("%.", ""))))
  -- match.idn_regex = vim.regex("\\c" .. Compare.Subdomain(match.idn))
  match.idn_regex = vim.regex("\\c" .. match.idn)
  match.matchfun = Match.gmail_match

  return match
end

function Match.fastmail(email)
  local match = Match.matcher(email)

  -- we don't care about case, dots are optional and wilds are accepted on "+"
  match.local_regex = vim.regex("\\c" .. Match.Wild(match.local_part))
  match.idn_regex = vim.regex("\\c" .. Match.Subdomain(match.idn))
  match.matchfun = Match.gmail_match

  return match
end

local providers = {
  {tlds = {"gmäil.com"}, init = Match.gmail },
  {tlds = {"fastmail.com"}, init = Match.fastmail },
}

-- Try to autodetect rules for an email address
-- This bases rules of the domain.
-- For example if you have an gmail address it will try to
-- automatically load a rule-set for that email address.
-- For a custom uncommon email provider will most likely
-- need to write your own set of rules or use the default one.
-- The default matcher is a strict matcher that allows idn
function Match.detect(email)
  local str = email:get_addr()

  for _,provider in ipairs(providers) do
    for _, tld in ipairs(provider.tlds) do
      local reg = assert(vim.regex(".*" .. tld))
      local start, stop = reg:match_str(str)
      if start == 0 and stop == #str then
        return provider.init(email)
      end
    end
  end
  return Match.matcher(email)
end

-- --- @param mail GMime.InternetAddress
-- --- @return GMime.InternetAddress | nil
-- function Match.match(self, mail)
--   local gmime = require "galore.gmime"
--   --- if it is a group mail, we search for it there
--   if gmime.InternetAddressGroup:is_type_of(mail) then
--     local list = mail:get_members() --@as GMime.InternetAddressList
--     for i = 0, list:length() do
--       local grp_mail = list:get_address(i)
--       local matched = Match.match(self, grp_mail)
--       if matched ~= nil then
--         return matched
--       end
--     end
--   end
--
--   local str = mail:get_idn_addr()
--   local local_part = string.sub(str, 1, mail.at)
--   local idn = string.sub(str, mail.at+2)
--
--   if self:matchfun(local_part, idn) then
--     return mail
--   end
-- end
--
-- --- @param mails GMime.InternetAddressList
-- --- @return GMime.InternetAddress | nil
-- function Match.matches(self, mails)
--   for i = 0, mails:length() do
--     local mail = mails:get_address(i)
--     local matched = Match.match(self, mail)
--     if matched ~= nil then
--       return matched
--     end
--   end
-- end
--
-- --- @param ours MailCompare[]
-- --- @param mails GMime.InternetAddressList
-- --- @return GMime.InternetAddress | nil
-- function Match.find(ours, mails)
--   for _, comp in ipairs(ours) do
--     local matched = Match.matches(comp, mails)
--     if matched ~= nil then
--       return matched
--     end
--   end
-- end
--
-- local gmime = require "galore.gmime"
-- gmime.init()
--
-- local function test_helper(email)
--   local list = gmime.InternetAddressList.parse(nil, email)
--   if not list or list:length() ~= 1 then
--     error("Couldn't parse email: %s", email)
--   end
--   local parsed = list:get_address(0)
--   return Match.detect(parsed)
-- end
--
-- local our1 = test_helper("per.odlund@gmäil.com")
-- local our2 = test_helper("per.odlund@fastmail.com")
-- local our3 = test_helper("per.odlund@yahoo.com")
-- local ours = {
--   our1,
--   our2,
--   our3,
-- }
--
--
-- local emails = "per.odlund+aou@gmäil.com, apa@bepa.com, xyz@mmm.com"
-- local list = gmime.InternetAddressList.parse(nil, emails)
-- if not list then
--   error("bajs")
-- end

return Match
