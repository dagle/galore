local gu = require('galore.gmime-util')
local ac = require('galore.address-compare')

local r = require('galore.render')
local config = require('galore.config')
local runtime = require('galore.runtime')
local u = require('galore.util')
local gmime = require("galore.gmime")
local log = require('galore.log')

local Templ = {}

local function addrlist_parse(str)
  local ialist = gmime.InternetAddressList.parse(runtime.parser_opts, str)
  return ialist
end

--- A class to describe an email template.
--- A template is like a mime email but much simplified.
--- It represents the what an email would look like on the screen.
--- This doesn't mean that we can't construct more interesting emails.
--- Galore allows you to specify a builder that can do all mime stuff

--- Headers have the type headervalue, it's either a string or a internetaddresslist.

--- @alias Path_attachment {filename: string, path: string, mime_type: string}
--- @alias Part_attachment {filename: string, part: GMime.Part, mime_type: string}
--- @alias Data_attachment {filename: string, data: userdata, mime_type: string}

--- @alias Attachment Path_attachment | Part_attachment | Data_attachment

--- @class template
--- headers can't contain any of the headers in addresses
--- or date etc. Doing so will cause UB and overwrite it.
--- @field headers table<string, string>
--- @field addresses table<string, gmime.InternetAddressList>
--- @field date glib.GDateTime|nil
--- @field body string[]
--- @field attachments Attachment[]

-- TODO, make things more composable
-- Atm we overwrite all the headers instead of merging them
-- Maybe we should reparse the message before we pass,
-- that way we don't have to worry about destorying it

-- TODO move helper functions that could be useful for outside of this file

-- Get the first none-nil value in a list of fields
--- Can use non-standard fields
local function get_backup(message, list)
  for _, v in ipairs(list) do
    local addr = message:get_addresses(v)
    if addr ~= nil and addr:length(addr) > 0 then
      return addr
    end
  end
end

local function get_backup_header(message, list)
  for _, v in ipairs(list) do
    local header = message:get_header(v)
    if header ~= nil and header:length(header) > 0 then
      return header
    end
  end
end

local function get_backup_addresses(message, list)
  for _, v in ipairs(list) do
    local header = message:get_header(v)
    if header ~= nil and header:length(header) > 0 then
      local addr = gmime.InternetAddressList.parse(nil, header)
      if addr then
        return addr
      end
    end
  end
end

-- local function remove(list, addr)
--   local i = 0
--   for demail in gu.internet_address_list_iter(list) do
--     if ac.address_equal(demail, addr) then
--       list:remove_at(i)
--       return true
--     end
--     i = i + 1
--   end
--   return false
-- end

-- local function append_no_dup(addr, dst)
--   local matched = ac.ialist_contains(addr, dst)
--   if not matched then
--     dst:add(addr)
--   end
-- end

-- local function PP(list)
--   return list:to_string(nil, false)
-- end

local function pp(header)
  if glib.DateTime:is_type_of(header) then
    return gmime.utils_header_format_date(header)
  end
  if gmime.InternetAddressList:is_type_of(header) or gmime.InternetAddressList:is_type_of(header) then
    return header:to_string(nil, false)
  else
    return tostring(header)
  end
end

--- prints the address/addresses and then reparses them.
local function clone(addresses)
  local str = pp(addresses)
  return gmime.InternetAddressList.parse(nil, str)
end

local function ialist(...)
  local l = gmime.InternetAddressList.new()

  for i = 1, select('#', ...) do
    local ia = select(i, ...)
    if ia then
      l:add(ia)
    end
  end
  return l
end

-- local function safelist(...)
--   local list = {}
--   for i = 1, select('#', ...) do
--     local value = select(i, ...)
--     if value then
--       table.insert(list, value)
--     end
--   end
--   return list
-- end

--- TODO: add support for IA
local function issubscribed(addresses)
  local str = table.concat(config.values.mailinglist_subscribed, ', ')
  local list = gmime.InternetAddressList.parse(runtime.parser_opts, str)
  for v in gu.internet_address_list_iter(list) do
    if ac.ialist_contains(v, addresses) then
      return true
    end
  end
end


local function get_key(gpg_id)
  local ctx = gmime.GpgContext.new()
  local mem = gmime.StreamMem.new()
  ctx:export_keys({ gpg_id }, mem)
  return mem:get_byte_array()
end

--- this is wrong because we don't want to add a key as an attachments
--- TODO make some default builders
function Templ:send_key(pgp_id)
  local attachments = self.attachments or {}
  pgp_id = pgp_id or config.values.pgp_id
  local key = get_key(pgp_id)
  table.insert(
    attachments,
    { filename = 'opengpg_pubkey.asc', data = key, mime_type = 'application/pgp-keys' }
  )
  self.attachments = attachments
end

function Templ:load_body(message, opts)
  local bufrender = r.new({
    verify = false,
  }, r.default_render)
  local buffer = {}
  local state = r.render_message(bufrender, message, buffer, opts)
  self.body = buffer
  vim.list_extend(self.attachments, state.attachments)
end

function Templ.load_headers(message, opts)
  opts = opts or {}
  local headers = {}
  for k, v in gu.header_iter(message) do
    headers[k] = v
  end
  opts.headers = headers
end

function Templ.subscribed(message)
  local to = message:get_to(message)
  local cc = message:get_cc(message)
  if issubscribed(to) or issubscribed(cc) then
    return true
  end
end

function Templ:mft_insert()
  local headers = self.headers
  headers['Mail-Reply-To'] = self.headers['Reply-To']
  local to = headers.to
  local cc = headers.cc
  if issubscribed(to) or issubscribed(cc) then
    --- should we remove look and remove dups?
    --- because an address could be in both to and cc
    headers['Mail-Followup-To'] = ialist(headers.to, headers.cc)
  end
  self.headers = headers
end

function Templ:dump_headers()
  local addresses = {}

  for k, address in pairs(self.addresses) do
    k = gu.show_addr(k)
    addresses[k] = address:to_string()
  end

  return vim.tbl_deep_extend("keep", addresses, self.headers)
end

function Templ.buffer(buffer, headers)
  local msg = Templ:new()

  for _, header in headers do
    local addr = gu.addr_type(header)
    if addr then
      msg.addresses[header] = gmime.InternetAddressList.parse(nil, header)
    else
      msg.headers = header
    end
  end

  for _, header in buffer.headers do
    local addr = gu.addr_type(header)
    if addr then
      msg.addresses[header] = gmime.InternetAddressList.parse(nil, header)
    else
      msg.headers = header:gsub("^%l", string.upper)
    end
  end
end

function Templ:mft_insert_notsubbed(message)
  local headers = self.headers
  headers['Mail-Reply-To'] = pp(self.headers['Reply-To'])
  local to = headers.to
  local cc = headers.cc
  local ml = message:get_header('List-Post')
  if ml and not (issubscribed(to) or issubscribed(cc)) then
    ml = gmime.InternetAddressList.parse(nil, ml)
    ml:add(headers.From)
    headers['Mail-Followup-To'] = ml
  end
  self.headers = headers
end

-- function M.smart_response(old_message, msg, opts)
--   local ml = old_message:get_header('List-Post')
--   if ml then
--     opts.type = 'mailinglist'
--   end
--   M.response_message(old_message, msg, opts)
-- end

local function response_addr(message, field, filter)
end

local function add_no_dup(message, field)
end

function Templ.compose_new()
  local msg = {}
  local headers = {}
  local addresses = {}
  local our = gmime.InternetAddressMailbox.new(config.values.name, config.values.primary_email)
  headers.from = our

  msg.headers = headers
  return msg
end

function Templ:mft_response(message, opts)
  local type = opts.type or 'reply'
  local addresses = self.addresses

  if type == 'reply' then
    local from = get_backup_addresses(message, { 'Mail-Reply-To', 'Reply-To', 'From', 'Sender' })
    addresses.to = from or addresses.to
  elseif type == 'reply_all' then
    local from = get_backup_addresses(message, { 'Mail-Followup-To', 'Reply-To', 'From', 'Sender' })
    addresses.to = from or addresses.to
  end
end

--- can we configure this some how?
function Templ:new (o)
  o = o or {
    headers = {},
    body = nil,
    attachments = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function Templ.response_message(message, opts)
  local msg = Templ:new()
  local addresses = msg.addresses
  local headers = msg.headers

  local at = gmime.AddressType

  local our = ialist(ac.get_our_email(message))
  msg.addresses = addresses

  addresses.to = our

  local sub = message:get_subject()
  headers.subject = u.add_prefix(sub, 'Re:')

  local from = get_backup(message, { at.REPLY_TO, at.FROM, at.SENDER })

  if not opts.type or opts.type == 'reply' then
    addresses.to = from
  elseif opts.type == 'reply_all' then

    addresses.to = response_addr(message, at.TO, our)
    add_no_dup(addresses.to, from)

    addresses.cc = response_addr(message, at.TO, our)
    addresses.bcc = response_addr(message, at.TO, our)
  elseif opts.type == 'mailinglist' then
    local ml = message:get_header('List-Post')
    if ml then
      addresses.to = gmime.InternetAddressList.parse(nil, ml)
    end
  end

  return msg
end

local function resent(message, to)
  local msg = Templ:new()
  local headers = msg.headers
  local at = gmime.AddressType

  local our = ialist(ac.get_our_email(message))

  headers.from = our

  headers.to = to

  headers['Resent-To'] = pp(message:get_address(at.TO))
  headers['Resent-From'] = pp(message:get_address(at.FROM))
  headers['Resent-Cc'] = pp(message:get_address(at.CC))
  headers['Resent-Bcc'] = pp(message:get_address(at.BCC))
  headers['Recent-Date'] = pp(message:get_date())
  headers['Recent-Id'] = message:get_message_id()
  -- insert before the body
  msg.headers = headers

  return msg
end

function Templ.forward_resent(message, to_str)
  local to = gmime.InternetAddressList.parse(nil, to_str)

  local msg = resent(message, to)

  local sub = message:get_subject()
  sub = u.add_prefix(sub, 'FWD:')
  msg.headers.subject = sub

  table.insert(msg.body, 1, { '--- Forwarded message ---' })

  return msg
end

function Templ.bounce(message)
  local at = gmime.AddressType
  local from = get_backup(message, { at.REPLY_TO, at.FROM, at.SENDER })

  local msg = resent(message, from)

  local sub = message:get_subject()
  sub = u.add_prefix(sub, 'Return:')
  msg.headers.subject = sub

  table.insert(msg.body, 1, { "--- This email isn't for me ---" })
  return msg
end

function Templ.subscribe(message)
  local msg = Templ:new()
  local headers = msg.headers

  local unsub = message:get_header('List-Subscribe')
  if unsub == nil then
    log.error('Subscribe header not found')
  end
  local addr = ac.get_our_email(message)
  headers.from = { config.values.name, addr }
  headers.to = u.unmailto(unsub)
  headers.subject = 'Subscribe'
end

function Templ.unsubscribe(message)
  local msg = Templ:new()
  local headers = msg.headers

  local unsub = message:get_header('List-Unsubscribe')
  if unsub == nil then
    log.error('Subscribe header not found')
  end
  local addr = ialist(ac.get_our_email(message))
  headers.from = { config.values.name, addr }
  headers.to = u.unmailto(unsub)
  headers.subject = 'Unsubscribe'
end

return Templ
