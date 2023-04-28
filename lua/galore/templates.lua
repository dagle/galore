local gu = require('galore.gmime-util')
local au = require('galore.address-util')

local r = require('galore.render')
local config = require('galore.config')
local runtime = require('galore.runtime')
local u = require('galore.util')
local gmime = require("galore.gmime")
local log = require('galore.log')

local M = {}

local function addrlist_parse(str)
  local ialist = gmime.InternetAddressList.parse(runtime.parser_opts, str)
  return ialist
end

--- A class to describe an email template.
--- A template is like a mime email but much simplified.
--- It represents the what an email would look like on the screen.
--- This doesn't mean that we can't construct more interesting emails.
--- Galore allows you to specify a builder that can do all mime stuff

--- @class template
--- @field headers table|nil
--- @field body string|nil
--- @field attachments table|nil


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
  return nil
end

local function remove(list, addr)
  local i = 0
  for demail in gu.internet_address_list_iter(list) do
    if au.address_equal(demail, addr) then
      list:remove_at(i)
      return true
    end
    i = i + 1
  end
  return false
end

local function append_no_dup(addr, dst)
  local matched = au.ialist_contains(addr, dst)
  if not matched then
    dst:add(addr)
  end
end

local function PP(list)
  return list:to_string(nil, false)
end

local function pp(ia)
  return ia:to_string(nil, false)
end

local function safelist(...)
  local list = {}
  for i = 1, select('#', ...) do
    local value = select(i, ...)
    if value then
      table.insert(list, value)
    end
  end
  return list
end

local function issubscribed(addresses)
  local str = table.concat(config.values.mailinglist_subscribed, ', ')
  local list = gmime.InternetAddressList.parse(runtime.parser_opts, str)
  for v in gu.internet_address_list_iter(list) do
    if au.ialist_contains(v, addresses) then
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

function M.compose_new(msg)
  local headers = msg.headers or {}
  local our = gmime.InternetAddressMailbox.new(config.values.name, config.values.primary_email)
  headers.from = pp(our)

  msg.headers = headers
end

--- this is wrong because we don't want to add a key as an attachments
--- TODO make some default builders
function M.mailkey(msg, pgp_id)
  local attachments = msg.attachments or {}
  pgp_id = pgp_id or config.values.pgp_id
  local key = get_key(pgp_id)
  table.insert(
    attachments,
    { filename = 'opengpg_pubkey.asc', data = key, mime_type = 'application/pgp-keys' }
  )
  msg.attachments = attachments
end

function M.load_body(message, msg)
  local bufrender = r.new({
    verify = false,
  }, r.default_render)
  local buffer = {}
  local state = r.render_message(bufrender, message, buffer, msg)
  msg.body = buffer
  msg.attachments = state.attachments
end

function M.load_headers(message, opts)
  opts = opts or {}
  local headers = {}
  for k, v in gu.header_iter(message) do
    headers[k] = v
  end
  opts.headers = headers
end

function M.subscribed(old_message)
  local to = old_message:get_to(old_message)
  local cc = old_message:get_cc(old_message)
  if issubscribed(to) or issubscribed(cc) then
    return true
  end
end

--- TODO clean up mft stuff
function M.mft_response(old_message, msg, opts)
  local headers = msg.headers or {}
  if not opts.type or opts.type == 'author' then
    local from = get_backup_header(old_message, { 'Mail-Reply-To', 'reply_to', 'from', 'sender' })
    headers.to = from
  elseif opts.type == 'reply_all' then
    local mft = old_message:get_header('Mail-Followup-To')
    if mft ~= nil then
      local ialist = gmime.InternetAddressList.parse(runtime.parser_opts, mft)
      headers.to = PP(ialist)
    else
      M.response_message(old_message, msg, opts)
    end
  end
  msg.headers = headers
end

function M.mft_insert(msg)
  local headers = msg.headers
  headers['Mail-Reply-To'] = msg.headers['Reply-To']
  local to = addrlist_parse(headers.to)
  local cc = addrlist_parse(headers.cc)
  if issubscribed(to) or issubscribed(cc) then
    --- should we remove look and remove dups?
    --- because an address could be in both to and cc
    headers['Mail-Followup-To'] = table.concat(safelist(headers.to, headers.Cc), ',')
  end
  msg.headers = headers
end

function M.mft_insert_notsubbed(old_message, msg)
  local headers = msg.headers
  headers['Mail-Reply-To'] = msg.headers['Reply-To']
  local to = addrlist_parse(headers.to)
  local cc = addrlist_parse(headers.cc)
  local ml = old_message:get_header('List-Post')
  if ml ~= nil and not (issubscribed(to) or issubscribed(cc)) then
    ml = PP(ml)
    headers['Mail-Followup-To'] = table.concat(safelist(headers.From, ml), ',')
  end
  msg.headers = headers
end

function M.smart_response(old_message, msg, opts)
  local ml = old_message:get_header('List-Post')
  if ml then
    opts.type = 'mailinglist'
  end
  M.response_message(old_message, msg, opts)
end


--- takes an addresslist and adds unqiue
function fix_response(addresses, adds, removes)
end

function M.response_message(old_message, msg, opts)
  opts = opts or {}
  local at = gmime.AddressType
  local headers = msg.headers or {}

  local addr = au.get_our_email(old_message)
  local our = gmime.InternetAddressMailbox.new(config.values.name, addr)
  local our_str = pp(our)

  local sub = old_message:get_subject()

  headers.subject = u.add_prefix(sub, 'Re:')

  headers.from = our_str

  local from = get_backup(old_message, { at.REPLY_TO, at.FROM, at.SENDER }):get_address(0)
  if not opts.type or opts.type == 'reply' then
    headers.to = pp(from)
  elseif opts.type == 'reply_all' then
    --- these are destructive
    local to = old_message:get_addresses(at.TO)
    headers.to = fix_response(to, {from}, {our})
    -- append_no_dup(from, to)
    -- remove(to, our)
    -- headers.to = PP(to)

    local cc = old_message:get_addresses(at.CC)
    headers.cc = fix_response(cc, {}, {our})
    -- remove(to, our)
    -- headers.cc = PP(cc)

    local bcc = old_message:get_addresses(at.BCC)
    -- remove(to, our)
    -- headers.bcc = PP(bcc)
    headers.cc = fix_response(bcc, {}, {our})
  elseif opts.type == 'mailinglist' then
    local ml = old_message:get_header('List-Post')
    headers.to = u.unmailto(ml)
  end
  msg.headers = headers
end

local function resent(old_message, to_str, msg)
  local at = gmime.AddressType
  local headers = msg.headers or {}

  local addr = au.get_our_email(old_message)
  local our = gmime.InternetAddressMailbox.new(config.values.name, addr)
  local our_str = pp(our)
  headers.from = our_str

  headers.to = to_str

  headers['Resent-To'] = PP(old_message:get_address(at.TO))
  headers['Resent-From'] = PP(old_message:get_address(at.FROM))
  headers['Resent-Cc'] = PP(old_message:get_address(at.CC))
  headers['Resent-Bcc'] = PP(old_message:get_address(at.BCC))
  headers['Recent-Date'] = old_message:get_date()
  headers['Recent-Id'] = old_message:get_message_id()
  -- insert before the body
  msg.headers = headers
end

function M.forward_resent(old_message, to_str, msg)
  resent(old_message, to_str, msg)

  local sub = old_message:get_subject()
  sub = u.add_prefix(sub, 'FWD:')
  msg.headers.subject = sub

  -- insert before the body
  table.insert(msg.body, 1, { '--- Forwarded message ---' })
end

function M.bounce(old_message, msg)
  local at = gmime.AddressType
  local from = get_backup(old_message, { at.REPLY_TO, at.FROM, at.SENDER }):get_address(0):to_string(nil, false)
  resent(old_message, from, msg)

  local sub = old_message:get_subject()
  sub = u.add_prefix(sub, 'Return:')
  msg.headers.subject = sub

  table.insert(msg.body, 1, { "--- This email isn't for me ---" })
  msg.attachments = {} -- do not bounce the attachments
end

function M.subscribe(old_message, msg)
  local unsub = old_message:get_header('List-Subscribe')
  if unsub == nil then
    log.error('Subscribe header not found')
  end
  local addr = au.get_our_email(old_message)
  local headers = msg.headers or {}
  headers.from = { config.values.name, addr }
  headers.to = u.unmailto(unsub)
  headers.subject = 'Subscribe'
  msg.headers = headers
end

function M.unsubscribe(old_message, msg)
  local unsub = old_message:get_header('List-Unsubscribe')
  if unsub == nil then
    log.error('Subscribe header not found')
  end
  local addr = au.get_our_email(old_message)
  local headers = msg.headers or {}
  headers.from = { config.values.name, addr }
  headers.to = u.unmailto(unsub)
  headers.subject = 'Unsubscribe'
  msg.headers = headers
end

return M
