local config = require('galore.config')
local gu = require('galore.gmime-util')
local gmime = require("galore.gmime")

local M = {}

-- TODO:
--- most of this should be rewritten
--- gmime-extra so it can be used in gmime-extra

local function unwild(ia)
  -- local myString = "some+text+here"
  local addr = ia:get_addr()
  local index, _ = string.find(addr, "+") -- Find the index of the first '+' character
  local at, _ = string.find(addr, "@") -- Find the index of the first '+' character
  if index and at < index then
    addr = string.sub(addr, index + 1) -- Extract the substring starting from the character after the first '+'
  end
  -- print(myString) -- Output: "text+here"
  return addr
end

-- TODO expose
local function normalize(ia1)
  if gmime.InternetAddressMailbox:is_type_of(ia1) then
    return ia1:get_idn_addr()
  end
  return ia1:to_string()
end

-- TODO expose
local function removetags(emailstr)
  return emailstr.gsub('[+-].-@', '@')
end

function M.address_equal(ia1, ia2)
  -- we don't support groups for now
  local e1 = normalize(ia1)
  local e2 = normalize(ia2)
  return unwild(e1) == unwild(e2)
end

--- TODO move all compare functions to it's own file
function M.ialist_contains(ia2, ialist)
  for ia1 in gu.internet_address_list_iter(ialist) do
    if M.address_equal(ia1, ia2) then
      return true
    end
  end
  return false
end

local function search_for(received, ourlist)
  local match, num = string.gsub(received, '.*by <?[^@]*@([^ >]*).*', '%1')
  if num > 0 then
    for _, mail in gu.internet_address_list_iter(ourlist) do
      local e = normalize(mail)
      -- TODO match might not be idn normalized
      if e:find(match) then
        return e
      end
    end
  end
end

local function search_by(received, ourlist)
  local match, num = string.gsub(received, '.*for <?[^@]*@([^ >]*).*', '%1')
  if num > 0 then
    for _, mail in gu.internet_address_list_iter(ourlist) do
      local e = normalize(mail)
      -- TODO match might not be idn normalized
      if e:find(match) then
        return e
      end
    end
  end
end

--- TODO
local function guess_from(message, ourlist)
  -- local received = M.header_get_values(object, "Received")
  -- for _, r in ipairs(received) do
  -- 	search_for(r)
  -- end
  -- for _, r in ipairs(received) do
  -- 	search_by(r)
  -- end
  return nil
end

--- get what email addr we used to recieve this email
--- useful if you have multiple emails and want to respond
--- from the correct email
--- This looks horrible and is but it's kinda tho only way
--- and how is most mailers do it

--- TODO: This should always return a string
function M.get_our_email(message)
  local at = gmime.AddressType
  local emails = {}
  table.insert(emails, config.values.primary_email)
  vim.list_extend(emails, config.values.other_email)
  local str = table.concat(emails, ', ')
  local ourlist = gmime.InternetAddressList.parse(nil, str)
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
    if not addr then
      goto continue
    end
    for ia1 in gu.internet_address_list_iter(addr) do
      if M.ialist_contains(ia1, ourlist) then
        return ia1
      end
    end
    ::continue::
  end
  for _, h in ipairs(extra) do
    local header = message:get_header(h)
    if not header then
      goto continue
    end

    for ia1 in gu.internet_address_list_iter_str(header, nil) do
      if M.ialist_contains(ia1, ourlist) then
        return ia1
      end
    end
    ::continue::
  end

  if not config.values.guess_email then
    return config.values.primary_email
  end
  local guess = guess_from(message, ourlist)
  if guess then
    return guess
  end
  return config.values.primary_email
end

return M
