local config = require('galore.config')
local gu = require('galore.gmime-util')
local gmime = require("galore.gmime")

local nm = require "notmuch"
local runtime = require("galore.runtime")

local M = {}

-- -- TODO:
-- --- most of this should be rewritten
-- --- gmime-extra so it can be used in gmime-extra
--
-- local function unwild(ia)
--   -- local myString = "some+text+here"
--   local addr = ia:get_addr()
--   local index, _ = string.find(addr, "+") -- Find the index of the first '+' character
--   local at, _ = string.find(addr, "@") -- Find the index of the first '+' character
--   if index and at < index then
--     addr = string.sub(addr, index + 1) -- Extract the substring starting from the character after the first '+'
--   end
--   -- print(myString) -- Output: "text+here"
--   return addr
-- end
--
-- -- TODO expose
-- local function normalize(ia1)
--   if gmime.InternetAddressMailbox:is_type_of(ia1) then
--     return ia1:get_idn_addr()
--   end
--   return ia1:to_string()
-- end
--
-- -- TODO expose
-- local function removetags(emailstr)
--   return emailstr.gsub('[+-].-@', '@')
-- end
--
-- function M.address_equal(ia1, ia2)
--   -- we don't support groups for now
--   local e1 = normalize(ia1)
--   local e2 = normalize(ia2)
--   return unwild(e1) == unwild(e2)
-- end
--
-- --- TODO move all compare functions to it's own file
-- function M.ialist_contains(ia2, ialist)
--   for ia1 in gu.internet_address_list_iter(ialist) do
--     if M.address_equal(ia1, ia2) then
--       return true
--     end
--   end
--   return false
-- end
--
-- local function search_for(received, ourlist)
--   local match, num = string.gsub(received, '.*by <?[^@]*@([^ >]*).*', '%1')
--   if num > 0 then
--     for _, mail in gu.internet_address_list_iter(ourlist) do
--       local e = normalize(mail)
--       -- TODO match might not be idn normalized
--       if e:find(match) then
--         return e
--       end
--     end
--   end
-- end
--
-- local function search_by(received, ourlist)
--   local match, num = string.gsub(received, '.*for <?[^@]*@([^ >]*).*', '%1')
--   if num > 0 then
--     for _, mail in gu.internet_address_list_iter(ourlist) do
--       local e = normalize(mail)
--       -- TODO match might not be idn normalized
--       if e:find(match) then
--         return e
--       end
--     end
--   end
-- end

--- TODO
local function guess_from(nm_message, emails)
  local received = nm.header_get_values(nm_message, "received")
  if received then
    local tmp = gmime.InternetAddressList.parse(nil, received);

    local mb = compare_list(filter, tmp, emails)
    return mb
  end
end

--- Parse our email addresses into a list of email address
---@return GMime.InternetAddressList
local function ours()
  if config.ours then
    return config.ours
  end

  local emails = {}
  table.insert(emails, config.values.primary_email)
  vim.list_extend(emails, config.values.other_email)
  local str = table.concat(emails, ', ')
  local ourlist = gmime.InternetAddressList.parse(nil, str)

  if not ourlist then
    error("The emails in your config or in notmuch can't be parsed")
  end
  config.ours = ourlist

  return ourlist
end

--- Search the email for our email address.
--- If we fail we return our primary email address.
---@param message GMime.Message
---@return GMime.InternetAddressMailbox
function M.get_our_email(message)
  local at = gmime.AddressType

  local emails = ours()

  local normal = {
    at.TO,
    at.CC,
    at.BCC,
  }
  local extra = {
    'Envelope-to',
    'X-Original-To',
    'Delivered-To',
  }

  for _, h in ipairs(normal) do
    local addr = message:get_addresses(h)

    local mb = compare_list(filter, addr, emails)

    if mb then
      return mb
    end
  end

  local db = nm.db_open_with_config_raw(config.values.db_path, 0, config.values.nm_config, config.values.nm_profile)
  local nm_message = nm.db_find_message(db, message:get_message_id())
  for _, h in ipairs(extra) do
    local hdr = nm.message_get_header(nm_message, h)
    if hdr then
      local tmp = gmime.InternetAddressList.parse(nil, str);

      local mb = compare_list(filter, tmp, emails)

      if mb then
        nm.db_close(db)
        return mb
      end
    end
  end

  if not config.values.guess_email then
    nm.db_close(db)
    return config.values.primary_email
  end
  local guess = guess_from(nm_message, emails)
  nm.db_close(db)
  if guess then
    return guess
  end
  return config.values.primary_email
end

return M
