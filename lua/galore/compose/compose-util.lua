local gmime = require "galore.gmime"
local gu = require "galore.gmime-util"
local config = require "galore.config"
local ac = require "galore.address-compare"
local lgi = require "lgi"
local glib = lgi.GLib

local M = {}

--- Get the first none-nil value in a list of address fields
---@param message GMime.Message
---@param list GMime.AddressType[]
---@return GMime.InternetAddressList?
function M.get_backup(message, list)
  for _, v in ipairs(list) do
    local addr = message:get_addresses(v)
    if addr ~= nil and addr:length() > 0 then
      return addr
    end
  end
end

--- Get the first none-nil value in a list of header fields
--- Can use non-standard fields
---@param message GMime.Message
---@param list string[]
---@return string?
function M.get_backup_header(message, list)
  for _, v in ipairs(list) do
    local header = message:get_header(v)
    if header ~= nil and header:len() > 0 then
      return header
    end
  end
end

--- Try to get the first none-nil address in a list of header fields
--- Can use non-standard fields and isn't limited to conventional
--- address fields
---@param message GMime.Message
---@param list string[]
---@return GMime.InternetAddressList?
function M.get_backup_addresses(message, list)
  for _, v in ipairs(list) do
    local header = message:get_header(v)
    if header ~= nil and header:len() > 0 then
      local addr = gmime.InternetAddressList.parse(nil, header)
      if addr then
        return addr
      end
    end
  end
end

--- @param header any
--- @return string
function M.pp(header)
  if glib.DateTime:is_type_of(header) then
    return gmime.utils_header_format_date(header)
  end
  if gmime.InternetAddressList:is_type_of(header) or gmime.InternetAddressList:is_type_of(header) then
    return header:to_string(nil, false)
  else
    return tostring(header)
  end
end

--- @param address GMime.InternetAddressList
--- @return GMime.InternetAddressList
function M.clone(address)
  local str = M.pp(address)
  return gmime.InternetAddressList.parse(nil, str) --[[@as GMime.InternetAddressList]]
end

--- If we need this function, I feel like we have done something wrong
-- local function ialist(...)
--   local l = gmime.InternetAddressList.new()
--
--   for i = 1, select('#', ...) do
--     local ia = select(i, ...)
--     if ia then
--       l:add(ia)
--     end
--   end
--   return l
-- end

function M.issubscribed(addresses)
  local str = table.concat(config.values.mailinglist_subscribed, ", ")
  local list = gmime.InternetAddressList.parse(nil, str)
  for v in gu.internet_address_list_iter(list) do
    if ac.ialist_contains(v, addresses) then
      return true
    end
  end
end

function M.get_key(gpg_id)
  local ctx = gmime.GpgContext.new()
  local mem = gmime.StreamMem.new()
  ctx:export_keys({ gpg_id }, mem)
  return mem:get_byte_array()
end

--- write these in C

--- Clone all addresses in a message for the message type where
--- the message but filters the out the addresses.
---@param message GMime.Message
---@param type GMime.AddressType
---@param address GMime.InternetAddress|GMime.InternetAddressList
function M.response_address(message, type, address) end

---@param addresses GMime.InternetAddressList
function M.filter_address(addresses, filter) end
return M
